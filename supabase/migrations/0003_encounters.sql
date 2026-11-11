-- Derived encounter rows only. Raw presence evidence remains private.
create table if not exists public.encounters (
  id uuid primary key default gen_random_uuid(),
  user_a uuid not null references auth.users(id) on delete cascade,
  user_b uuid not null references auth.users(id) on delete cascade,
  context_id text not null,
  overlap_start timestamptz not null,
  overlap_end timestamptz not null,
  created_at timestamptz not null default now(),
  evidence_a_id uuid references public.presence_evidence(id),
  evidence_b_id uuid references public.presence_evidence(id),
  constraint encounters_distinct_users check (user_a <> user_b),
  constraint encounters_valid_overlap check (overlap_end >= overlap_start),
  constraint encounters_canonical_pair check (user_a < user_b),
  unique (user_a, user_b, context_id, overlap_start, overlap_end)
);
alter table public.encounters enable row level security;
create policy "participants read derived encounters" on public.encounters for select to authenticated
  using (auth.uid() = user_a or auth.uid() = user_b);

create or replace function public.process_presence_evidence(p_evidence_id uuid)
returns setof public.encounters language plpgsql security definer set search_path = public
as $$
declare mine public.presence_evidence;
begin
  select * into mine from public.presence_evidence where id = p_evidence_id and subject_user_id = auth.uid();
  if not found then raise exception 'presence evidence unavailable'; end if;
  insert into public.encounters (user_a, user_b, context_id, overlap_start, overlap_end, evidence_a_id, evidence_b_id)
  select least(mine.subject_user_id, other.subject_user_id), greatest(mine.subject_user_id, other.subject_user_id),
    mine.context_id, greatest(mine.observed_start, other.observed_start), least(mine.observed_end, other.observed_end),
    case when mine.subject_user_id < other.subject_user_id then mine.id else other.id end,
    case when mine.subject_user_id < other.subject_user_id then other.id else mine.id end
  from public.presence_evidence other
  where other.subject_user_id <> mine.subject_user_id and other.context_id = mine.context_id
    and least(mine.observed_end, other.observed_end) - greatest(mine.observed_start, other.observed_start) >= interval '5 minutes'
    and least(mine.observed_end, other.observed_end) >= greatest(mine.observed_start, other.observed_start)
  on conflict do nothing;
  return query select * from public.encounters where auth.uid() = user_a or auth.uid() = user_b;
end; $$;
revoke all on function public.process_presence_evidence(uuid) from public;
grant execute on function public.process_presence_evidence(uuid) to authenticated;
