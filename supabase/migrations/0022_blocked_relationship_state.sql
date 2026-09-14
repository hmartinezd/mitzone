create or replace function public.get_relationship_state(p_other_user_id uuid, p_encounter_id uuid default null) returns text language plpgsql security definer set search_path=public as $$
declare me uuid := auth.uid(); state text;
begin
  if me is null or me = p_other_user_id then raise exception 'unauthorized'; end if;
  if exists(select 1 from blocks b where (b.blocker_user_id=me and b.blocked_user_id=p_other_user_id) or (b.blocker_user_id=p_other_user_id and b.blocked_user_id=me)) then return 'blocked'; end if;
  if exists(select 1 from connections c where c.user_a_id=least(me,p_other_user_id) and c.user_b_id=greatest(me,p_other_user_id)) then return 'connected'; end if;
  select case when r.sender_user_id=me then 'outgoingPending' else 'incomingPending' end into state from connection_requests r where r.status='pending' and ((r.sender_user_id=me and r.recipient_user_id=p_other_user_id) or (r.sender_user_id=p_other_user_id and r.recipient_user_id=me)) and (p_encounter_id is null or r.encounter_id=p_encounter_id) order by r.created_at desc limit 1;
  return coalesce(state,'none');
end; $$;
