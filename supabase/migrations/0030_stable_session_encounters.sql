-- One encounter per canonical evidence/session-segment pair, not one per
-- refresh timestamp. Segment starts change after a visit gap or cell movement.
alter table public.encounters
  add column evidence_a_observed_start timestamptz,
  add column evidence_b_observed_start timestamptz;

-- Retain every historical ID and its relationship references. Where current
-- evidence still identifies a segment, anchor further refreshes to one existing
-- row (prefer a row referenced by a request/connection). Never rewrite history
-- from evidence whose segment has already changed.
with candidates as (
  select e.id,a.observed_start as a_start,b.observed_start as b_start,
    row_number() over (
      partition by e.evidence_a_id,e.evidence_b_id,a.observed_start,b.observed_start
      order by (exists(select 1 from public.connection_requests r where r.encounter_id=e.id)
        or exists(select 1 from public.connections c where c.encounter_id=e.id)) desc,
        e.created_at,e.id
    ) as ordinal
  from public.encounters e
  join public.presence_evidence a on a.id=e.evidence_a_id and a.subject_user_id=e.user_a
  join public.presence_evidence b on b.id=e.evidence_b_id and b.subject_user_id=e.user_b
  where e.overlap_start=greatest(a.observed_start,b.observed_start)
    and e.overlap_end<=least(a.observed_end,b.observed_end)
)
update public.encounters e
  set evidence_a_observed_start=c.a_start,evidence_b_observed_start=c.b_start
  from candidates c where c.id=e.id and c.ordinal=1;

-- Replace the timestamp-based natural key. Dropping that constraint never
-- deletes rows or changes any ID/foreign key; nullable historical rows remain.
do $$ declare old_key record; begin
  for old_key in select conname from pg_constraint
    where conrelid='public.encounters'::regclass and contype='u'
      and pg_get_constraintdef(oid)='UNIQUE (user_a, user_b, context_id, overlap_start, overlap_end)'
  loop
    execute format('alter table public.encounters drop constraint %I',old_key.conname);
  end loop;
end $$;
alter table public.encounters add constraint encounters_evidence_segment_key
  unique(evidence_a_id,evidence_b_id,evidence_a_observed_start,evidence_b_observed_start);

create or replace function public.process_presence_evidence(p_evidence_id uuid)
returns setof public.encounters language plpgsql security definer
set search_path=public,pg_temp as $$
declare mine public.presence_evidence; stamp timestamptz:=clock_timestamp();
begin
  select * into mine from public.presence_evidence p
    where p.id=p_evidence_id and p.subject_user_id=auth.uid()
      and p.expires_at>stamp;
  if not found then raise exception 'presence evidence unavailable'; end if;
  insert into public.encounters as target
    (user_a,user_b,context_id,overlap_start,overlap_end,evidence_a_id,evidence_b_id,
      evidence_a_observed_start,evidence_b_observed_start)
  select least(mine.subject_user_id,other.subject_user_id),
    greatest(mine.subject_user_id,other.subject_user_id),
    case when mine.context_id=other.context_id then mine.context_id
      else least(mine.context_id,other.context_id)||'~nearby' end,
    greatest(mine.observed_start,other.observed_start),
    least(mine.observed_end,other.observed_end),
    case when mine.subject_user_id<other.subject_user_id then mine.id else other.id end,
    case when mine.subject_user_id<other.subject_user_id then other.id else mine.id end,
    case when mine.subject_user_id<other.subject_user_id then mine.observed_start else other.observed_start end,
    case when mine.subject_user_id<other.subject_user_id then other.observed_start else mine.observed_start end
  from public.presence_evidence other
  where other.subject_user_id<>mine.subject_user_id and other.expires_at>stamp
    and (other.context_id=mine.context_id or case
      when mine.context_id ~ '^cell:-?[0-9]+:-?[0-9]+$'
        and other.context_id ~ '^cell:-?[0-9]+:-?[0-9]+$' then
        abs(split_part(mine.context_id,':',2)::int-split_part(other.context_id,':',2)::int)<=1
        and abs(split_part(mine.context_id,':',3)::int-split_part(other.context_id,':',3)::int)<=1
      else false end)
    and least(mine.observed_end,other.observed_end)
      -greatest(mine.observed_start,other.observed_start)>=interval '5 minutes'
    and not exists(select 1 from public.blocks b
      where (b.blocker_user_id=mine.subject_user_id and b.blocked_user_id=other.subject_user_id)
        or (b.blocker_user_id=other.subject_user_id and b.blocked_user_id=mine.subject_user_id))
  on conflict on constraint encounters_evidence_segment_key do update
    set overlap_end=greatest(target.overlap_end,excluded.overlap_end);
  -- A security-definer result must enforce the same seven-day and symmetric
  -- block restrictions as the SELECT policy; bypassing RLS is not authorization.
  return query select e.* from public.encounters e
    where public.is_actionable_encounter(e.id,
      case when e.user_a=auth.uid() then e.user_b else e.user_a end);
end; $$;
