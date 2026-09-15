create table if not exists public.device_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  token text not null,
  platform text not null check (platform in ('android','ios','web')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  last_seen_at timestamptz not null default now(),
  constraint device_tokens_token_key unique (token)
);
alter table public.device_tokens enable row level security;
create index if not exists device_tokens_user_idx on public.device_tokens(user_id);
create policy "users manage own device tokens" on public.device_tokens
  for all to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);
revoke select, insert, update, delete on public.device_tokens from anon;
