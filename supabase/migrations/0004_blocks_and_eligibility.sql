create table if not exists public.blocks (
  blocker_user_id uuid not null references auth.users(id) on delete cascade,
  blocked_user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_user_id, blocked_user_id),
  constraint blocks_distinct_users check (blocker_user_id <> blocked_user_id)
);
alter table public.blocks enable row level security;
create policy "users manage own blocks" on public.blocks for all to authenticated
  using (auth.uid() = blocker_user_id) with check (auth.uid() = blocker_user_id);

drop policy if exists "participants read derived encounters" on public.encounters;
create policy "eligible participants read derived encounters" on public.encounters for select to authenticated
  using ((auth.uid() = user_a or auth.uid() = user_b) and not exists (
    select 1 from public.blocks b where
      (b.blocker_user_id = user_a and b.blocked_user_id = user_b) or
      (b.blocker_user_id = user_b and b.blocked_user_id = user_a)
  ));

create or replace function public.check_interaction_eligibility(p_other_user_id uuid)
returns boolean language sql security definer set search_path = public
as $$ select auth.uid() <> p_other_user_id and not exists (
  select 1 from public.blocks b where
    (b.blocker_user_id = auth.uid() and b.blocked_user_id = p_other_user_id) or
    (b.blocker_user_id = p_other_user_id and b.blocked_user_id = auth.uid())
); $$;
revoke all on function public.check_interaction_eligibility(uuid) from public;
grant execute on function public.check_interaction_eligibility(uuid) to authenticated;
