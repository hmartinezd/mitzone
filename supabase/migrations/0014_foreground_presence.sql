-- Foreground observations are quantized and persisted only as normal evidence.
alter table public.presence_evidence drop constraint if exists presence_evidence_source_check;
alter table public.presence_evidence add constraint presence_evidence_source_check
  check (source in ('eventParticipation', 'geolocation'));

create or replace function public.record_foreground_presence(
  p_latitude double precision,
  p_longitude double precision
) returns table(context_id text, observed_start timestamptz, observed_end timestamptz, expires_at timestamptz)
language plpgsql security definer set search_path = public
as $$
declare now_utc timestamptz := timezone('utc', now());
declare safe_context text;
declare evidence_id uuid := gen_random_uuid();
begin
  if auth.uid() is null then raise exception 'unauthorized'; end if;
  if p_latitude is null or p_longitude is null or p_latitude < -90 or p_latitude > 90 or p_longitude < -180 or p_longitude > 180 then raise exception 'invalid location'; end if;
  -- Approx. 1.1km latitude cells; coordinates are never stored or returned.
  safe_context := 'cell:' || round(p_latitude * 100)::text || ':' || round(p_longitude * 100)::text;
  insert into presence_evidence(id, subject_user_id, context_id, observed_start, observed_end, source, consent_scope, expires_at)
    values (evidence_id, auth.uid(), safe_context, now_utc, now_utc, 'geolocation', 'foreground-explicit', now_utc + interval '30 minutes')
    on conflict (subject_user_id, context_id) do update set observed_end = excluded.observed_end, expires_at = excluded.expires_at;
  perform process_presence_evidence(evidence_id);
  return query select p.context_id, p.observed_start, p.observed_end, p.expires_at
    from presence_evidence p where p.id = evidence_id;
end; $$;
revoke all on function public.record_foreground_presence(double precision,double precision) from public;
grant execute on function public.record_foreground_presence(double precision,double precision) to authenticated;
