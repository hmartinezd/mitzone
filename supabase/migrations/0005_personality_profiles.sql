create table if not exists public.personality_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  traits jsonb not null,
  questionnaire_version integer not null default 1,
  completed_at timestamptz not null default now(),
  visibility text not null default 'private' check (visibility in ('private','matching')),
  updated_at timestamptz not null default now()
);
alter table public.personality_profiles enable row level security;
create policy "users read permitted personality" on public.personality_profiles for select to authenticated using (auth.uid() = user_id or visibility = 'matching');
create policy "users insert own personality" on public.personality_profiles for insert to authenticated with check (auth.uid() = user_id);
create policy "users update own personality" on public.personality_profiles for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);
