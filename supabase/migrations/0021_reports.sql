create table if not exists public.reports (
  id uuid primary key default gen_random_uuid(),
  reporter_user_id uuid not null references auth.users(id) on delete cascade,
  reported_user_id uuid not null references auth.users(id) on delete cascade,
  reason text not null check (reason in ('harassment','inappropriateContent','fakeProfile','spam','safetyConcern','other')),
  details text check (details is null or char_length(details) <= 500),
  created_at timestamptz not null default now(),
  constraint reports_distinct_users check (reporter_user_id <> reported_user_id)
);
alter table public.reports enable row level security;
revoke all on public.reports from authenticated;
create policy "authenticated users submit reports" on public.reports for insert to authenticated with check (auth.uid() = reporter_user_id);
create unique index if not exists reports_recent_duplicate_idx on public.reports(reporter_user_id, reported_user_id, reason, date_trunc('hour', created_at at time zone 'UTC'));
