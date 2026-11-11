create table if not exists public.event_participation (
  user_id uuid not null references auth.users(id) on delete cascade,
  event_id text not null,
  joined_at timestamptz not null default timezone('utc', now()),
  primary key (user_id, event_id)
);

alter table public.event_participation enable row level security;

create policy "users manage own event participation"
  on public.event_participation for all to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

grant select, insert, update, delete on table public.event_participation to authenticated;
