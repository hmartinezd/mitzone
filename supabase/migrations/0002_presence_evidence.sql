create table if not exists public.presence_evidence (
  id uuid primary key,
  subject_user_id uuid not null references auth.users(id) on delete cascade,
  context_id text not null,
  observed_start timestamptz not null,
  observed_end timestamptz not null,
  source text not null check (source = 'eventParticipation'),
  confidence numeric check (confidence is null or (confidence >= 0 and confidence <= 1)),
  consent_scope text,
  expires_at timestamptz not null,
  created_at timestamptz not null default now(),
  unique(subject_user_id, context_id),
  check (observed_end >= observed_start),
  check (expires_at >= observed_end)
);
alter table public.presence_evidence enable row level security;
create policy "users manage own evidence" on public.presence_evidence for all to authenticated using (auth.uid() = subject_user_id) with check (auth.uid() = subject_user_id);
