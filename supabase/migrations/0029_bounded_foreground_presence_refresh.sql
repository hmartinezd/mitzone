-- Activation and refresh are separate commands. A refresh carries the server's
-- evidence UUID and can never create or revive a stopped/expired/newer session.
create or replace function public.record_foreground_presence(
  p_latitude double precision, p_longitude double precision
) returns table(evidence_id uuid, context_id text, observed_start timestamptz,
  observed_end timestamptz, expires_at timestamptz)
language plpgsql security definer set search_path = public, pg_temp as $$
declare stamp timestamptz; safe_context text; new_id uuid:=gen_random_uuid();
begin
  if auth.uid() is null then raise exception 'unauthorized'; end if;
  if p_latitude is null or p_longitude is null or p_latitude < -90
    or p_latitude > 90 or p_longitude < -180 or p_longitude > 180
    then raise exception 'invalid location'; end if;
  perform pg_advisory_xact_lock(hashtextextended('presence:' || auth.uid()::text,0));
  stamp := clock_timestamp();
  safe_context := 'cell:' || round(p_latitude*100)::text || ':' || round(p_longitude*100)::text;
  delete from public.presence_evidence
    where subject_user_id=auth.uid() and source='geolocation';
  insert into public.presence_evidence
    (id,subject_user_id,context_id,observed_start,observed_end,source,consent_scope,expires_at)
    values(new_id,auth.uid(),safe_context,stamp,stamp,
      'geolocation','foreground-explicit',stamp+interval '30 minutes');
  perform public.process_presence_evidence(new_id);
  return query select p.id,p.context_id,p.observed_start,p.observed_end,p.expires_at
    from public.presence_evidence p where p.id=new_id;
end; $$;

create function public.refresh_foreground_presence(
  p_evidence_id uuid, p_latitude double precision, p_longitude double precision
) returns table(evidence_id uuid, context_id text, observed_start timestamptz,
  observed_end timestamptz, expires_at timestamptz)
language plpgsql security definer set search_path = public, pg_temp as $$
declare stamp timestamptz; safe_context text; previous public.presence_evidence;
begin
  if auth.uid() is null then raise exception 'unauthorized'; end if;
  if p_latitude is null or p_longitude is null or p_latitude < -90
    or p_latitude > 90 or p_longitude < -180 or p_longitude > 180
    then raise exception 'invalid location'; end if;
  perform pg_advisory_xact_lock(hashtextextended('presence:' || auth.uid()::text,0));
  stamp := clock_timestamp();
  select * into previous from public.presence_evidence p
    where p.id=p_evidence_id and p.subject_user_id=auth.uid()
      and p.source='geolocation' and p.expires_at>stamp and p.observed_end<=stamp for update;
  if not found then raise exception 'presence session unavailable'; end if;
  safe_context := 'cell:' || round(p_latitude*100)::text || ':' || round(p_longitude*100)::text;
  update public.presence_evidence p
    set context_id=safe_context,
      observed_start=case when previous.context_id=safe_context
        and previous.observed_end>=stamp-interval '90 seconds'
        then previous.observed_start else stamp end,
      observed_end=stamp
    where p.id=previous.id;
  -- expires_at is intentionally unchanged even after observation gaps/movement.
  perform public.process_presence_evidence(previous.id);
  return query select p.id,p.context_id,p.observed_start,p.observed_end,p.expires_at
    from public.presence_evidence p where p.id=previous.id;
end; $$;
revoke all on function public.refresh_foreground_presence(uuid,double precision,double precision) from public;
grant execute on function public.refresh_foreground_presence(uuid,double precision,double precision) to authenticated;

-- The same owner lock serializes Stop against an in-flight refresh. Either the
-- refresh completes before Stop deletes it, or its UUID no longer exists.
create or replace function public.stop_foreground_presence()
returns void language plpgsql security definer set search_path = public, pg_temp as $$
begin
  if auth.uid() is null then raise exception 'unauthorized'; end if;
  perform pg_advisory_xact_lock(hashtextextended('presence:' || auth.uid()::text,0));
  delete from public.presence_evidence
    where subject_user_id=auth.uid() and source='geolocation';
end; $$;
