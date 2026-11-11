create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  recipient_user_id uuid not null references auth.users(id) on delete cascade,
  type text not null check (type in ('connectionRequest','connectionAccepted','newMessage')),
  actor_user_id uuid references auth.users(id) on delete set null,
  entity_id text,
  destination text,
  created_at timestamptz not null default now(),
  read_at timestamptz
);
alter table public.notifications enable row level security;
create index if not exists notifications_recipient_created_idx on public.notifications (recipient_user_id, created_at desc);
create index if not exists notifications_unread_idx on public.notifications (recipient_user_id) where read_at is null;
create policy "users read own notifications" on public.notifications for select to authenticated using (auth.uid() = recipient_user_id);
create policy "users update own notifications" on public.notifications for update to authenticated using (auth.uid() = recipient_user_id) with check (auth.uid() = recipient_user_id);
revoke insert, delete on public.notifications from authenticated;
