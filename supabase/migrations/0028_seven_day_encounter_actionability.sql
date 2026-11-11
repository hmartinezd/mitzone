-- Owner-approved private-beta policy: seven days from the last shared
-- observation. This is independent of the short-lived presence session.
create function public.is_actionable_encounter(p_encounter_id uuid, p_other_user_id uuid)
returns boolean language sql stable security definer
set search_path = public, pg_temp as $$
  select auth.uid() is not null and auth.uid() <> p_other_user_id
    and exists(select 1 from public.encounters e
      where e.id=p_encounter_id
        and e.overlap_end <= now()
        and e.overlap_end + interval '7 days' > now()
        and ((e.user_a=auth.uid() and e.user_b=p_other_user_id)
          or (e.user_b=auth.uid() and e.user_a=p_other_user_id)))
    and not exists(select 1 from public.blocks b
      where (b.blocker_user_id=auth.uid() and b.blocked_user_id=p_other_user_id)
        or (b.blocker_user_id=p_other_user_id and b.blocked_user_id=auth.uid()));
$$;
revoke all on function public.is_actionable_encounter(uuid,uuid) from public;
grant execute on function public.is_actionable_encounter(uuid,uuid) to authenticated;

-- Use a security-definer boundary so directional block RLS cannot hide the
-- other participant's block from an encounter read.
drop policy "eligible participants read derived encounters" on public.encounters;
create policy "eligible participants read derived encounters" on public.encounters
  for select to authenticated using(public.is_actionable_encounter(id,
    case when user_a=auth.uid() then user_b else user_a end));

create or replace function public.get_public_profiles(p_user_ids uuid[])
returns table(id uuid, display_name text, avatar_uri text, bio text, city text)
language sql security definer set search_path = public, pg_temp as $$
  select p.id,p.display_name,p.avatar_uri,p.bio,p.city
  from public.profiles p where p.id=any(p_user_ids)
    and (p.id=auth.uid() or (
      not exists(select 1 from public.blocks b
        where (b.blocker_user_id=auth.uid() and b.blocked_user_id=p.id)
          or (b.blocker_user_id=p.id and b.blocked_user_id=auth.uid()))
      and (exists(select 1 from public.encounters e
        where public.is_actionable_encounter(e.id,p.id))
        or exists(select 1 from public.connections c
          where c.terminated_at is null
            and ((c.user_a_id=auth.uid() and c.user_b_id=p.id)
              or (c.user_b_id=auth.uid() and c.user_a_id=p.id))))));
$$;

-- Preserve locked/idempotent mutual-consent commands; only actionability changes.
create or replace function public.accept_connection_request(p_request_id uuid)
returns public.connection_requests language plpgsql security definer set search_path=public,pg_temp as $$
declare r public.connection_requests;
begin
  select * into r from connection_requests where id=p_request_id;
  if not found or auth.uid() is null or r.recipient_user_id<>auth.uid() then raise exception 'request unavailable'; end if;
  perform lock_relationship_pair(r.sender_user_id,r.recipient_user_id);
  select * into r from connection_requests where id=p_request_id and recipient_user_id=auth.uid()
    and status='pending' and invalidated_at is null for update;
  if not found then raise exception 'request unavailable'; end if;
  if not exists(select 1 from encounters e where e.id=r.encounter_id and e.overlap_end <= now() and e.overlap_end + interval '7 days' > now()
    and ((e.user_a=r.sender_user_id and e.user_b=r.recipient_user_id)
      or (e.user_b=r.sender_user_id and e.user_a=r.recipient_user_id)))
    or exists(select 1 from blocks b
      where (b.blocker_user_id=r.sender_user_id and b.blocked_user_id=r.recipient_user_id)
         or (b.blocker_user_id=r.recipient_user_id and b.blocked_user_id=r.sender_user_id))
    then raise exception 'request unavailable'; end if;
  update connection_requests set status='accepted',responded_at=now() where id=r.id returning * into r;
  insert into connections(user_a_id,user_b_id,encounter_id,context_id)
    values(least(r.sender_user_id,r.recipient_user_id),greatest(r.sender_user_id,r.recipient_user_id),r.encounter_id,r.context_id)
    on conflict(user_a_id,user_b_id) where terminated_at is null do nothing;
  insert into notifications(recipient_user_id,type,actor_user_id,entity_id,destination)
    values(r.sender_user_id,'connectionAccepted',auth.uid(),r.id::text,'/app/matches') on conflict do nothing;
  return r;
end;
$$;

create or replace function public.send_connection_request(p_other_user_id uuid,p_encounter_id uuid)
returns public.connection_requests language plpgsql security definer set search_path=public,pg_temp as $$
declare old public.connection_requests; result public.connection_requests;
begin
  if auth.uid() is null or auth.uid()=p_other_user_id then raise exception 'unauthorized'; end if;
  perform lock_relationship_pair(auth.uid(),p_other_user_id);
  if not exists(select 1 from encounters e where e.id=p_encounter_id and e.overlap_end <= now() and e.overlap_end + interval '7 days' > now()
    and ((e.user_a=auth.uid() and e.user_b=p_other_user_id) or (e.user_b=auth.uid() and e.user_a=p_other_user_id)))
    then raise exception 'encounter unavailable'; end if;
  if exists(select 1 from blocks b
    where (b.blocker_user_id=auth.uid() and b.blocked_user_id=p_other_user_id)
       or (b.blocker_user_id=p_other_user_id and b.blocked_user_id=auth.uid())) then raise exception 'blocked'; end if;
  if exists(select 1 from connections where user_a_id=least(auth.uid(),p_other_user_id)
    and user_b_id=greatest(auth.uid(),p_other_user_id) and terminated_at is null) then raise exception 'already connected'; end if;
  select * into old from connection_requests where status='pending' and invalidated_at is null
    and ((sender_user_id=auth.uid() and recipient_user_id=p_other_user_id)
      or (sender_user_id=p_other_user_id and recipient_user_id=auth.uid())) order by created_at limit 1 for update;
  if old.id is not null then
    if old.sender_user_id=p_other_user_id then return accept_connection_request(old.id); end if;
    return old;
  end if;
  insert into connection_requests(sender_user_id,recipient_user_id,encounter_id)
    values(auth.uid(),p_other_user_id,p_encounter_id) returning * into result;
  insert into notifications(recipient_user_id,type,actor_user_id,entity_id,destination)
    values(p_other_user_id,'connectionRequest',auth.uid(),result.id::text,'/app/matches') on conflict do nothing;
  return result;
end;
$$;


-- Compatibility must not disclose stale or symmetrically blocked encounters.
create or replace function public.get_personality_compatibility(p_other_user_id uuid) returns jsonb language plpgsql security definer set search_path = public as $$
declare me public.personality_profiles; other public.personality_profiles; result numeric;
begin
  if auth.uid() is null or auth.uid() = p_other_user_id then return jsonb_build_object('state','unknown'); end if;
  if not exists(select 1 from public.encounters e where public.is_actionable_encounter(e.id,p_other_user_id)) then return jsonb_build_object('state','unknown'); end if;
  select * into me from public.personality_profiles where user_id=auth.uid(); select * into other from public.personality_profiles where user_id=p_other_user_id and visibility='matching';
  if me is null or other is null or me.visibility <> 'matching' then return jsonb_build_object('state','unknown'); end if;
  result := (1-abs((me.traits->>'openness')::numeric-(other.traits->>'openness')::numeric))*.25 + (1-abs((me.traits->>'conscientiousness')::numeric-(other.traits->>'conscientiousness')::numeric))*.2 + (1-abs((me.traits->>'agreeableness')::numeric-(other.traits->>'agreeableness')::numeric))*.25 + (1-abs((me.traits->>'emotionalStability')::numeric-(other.traits->>'emotionalStability')::numeric))*.2 + .5*.1;
  return jsonb_build_object('state','known','value',greatest(0,least(1,result)));
end; $$;
revoke all on function public.get_personality_compatibility(uuid) from public; grant execute on function public.get_personality_compatibility(uuid) to authenticated;
