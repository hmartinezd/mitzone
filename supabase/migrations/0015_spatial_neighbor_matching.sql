-- Immediate 3x3 coarse-cell neighborhood; event contexts remain exact.
create or replace function public.process_presence_evidence(p_evidence_id uuid)
returns setof public.encounters language plpgsql security definer set search_path = public
as $$
declare mine public.presence_evidence;
declare mine_cell text[];
begin
  select * into mine from public.presence_evidence where id = p_evidence_id and subject_user_id = auth.uid();
  if not found then raise exception 'presence evidence unavailable'; end if;
  mine_cell := regexp_split_to_array(substring(mine.context_id from 6), ':');
  insert into public.encounters (user_a, user_b, context_id, overlap_start, overlap_end, evidence_a_id, evidence_b_id)
  select least(mine.subject_user_id, other.subject_user_id), greatest(mine.subject_user_id, other.subject_user_id),
    case when mine.context_id = other.context_id then mine.context_id else mine.context_id || '~nearby' end,
    greatest(mine.observed_start, other.observed_start), least(mine.observed_end, other.observed_end),
    case when mine.subject_user_id < other.subject_user_id then mine.id else other.id end,
    case when mine.subject_user_id < other.subject_user_id then other.id else mine.id end
  from public.presence_evidence other
  where other.subject_user_id <> mine.subject_user_id
    and (other.context_id = mine.context_id or (mine.context_id like 'cell:%' and other.context_id like 'cell:%'
      and abs(mine_cell[1]::int - (regexp_split_to_array(substring(other.context_id from 6), ':'))[1]::int) <= 1
      and abs(mine_cell[2]::int - (regexp_split_to_array(substring(other.context_id from 6), ':'))[2]::int) <= 1))
    and least(mine.observed_end, other.observed_end) - greatest(mine.observed_start, other.observed_start) >= interval '5 minutes'
    and least(mine.observed_end, other.observed_end) >= greatest(mine.observed_start, other.observed_start)
    and not exists (select 1 from public.blocks b where (b.blocker_user_id=mine.subject_user_id and b.blocked_user_id=other.subject_user_id) or (b.blocker_user_id=other.subject_user_id and b.blocked_user_id=mine.subject_user_id))
  on conflict do nothing;
  return query select * from public.encounters where auth.uid() = user_a or auth.uid() = user_b;
end; $$;
revoke all on function public.process_presence_evidence(uuid) from public;
grant execute on function public.process_presence_evidence(uuid) to authenticated;
