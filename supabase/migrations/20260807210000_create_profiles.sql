-- Create profiles table
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null check (char_length(trim(display_name)) >= 2 and char_length(trim(display_name)) <= 50),
  avatar_url text,
  bio text,
  city text,
  languages jsonb not null default '[]'::jsonb,
  interests jsonb not null default '[]'::jsonb,
  connection_goal text,
  profile_completion integer not null default 0 check (profile_completion >= 0 and profile_completion <= 100),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Enable RLS
alter table public.profiles enable row level security;

-- Policies for profiles
create policy "Users can view their own profile" on public.profiles
  for select using (auth.uid() = id);

create policy "Users can insert their own profile" on public.profiles
  for insert with check (auth.uid() = id);

create policy "Users can update their own profile" on public.profiles
  for update using (auth.uid() = id);

create policy "Users can delete their own profile" on public.profiles
  for delete using (auth.uid() = id);

-- Future: Users can view other profiles (when discovery is implemented)
-- create policy "Profiles are viewable by everyone" on public.profiles
--   for select using (true);

-- Create storage bucket for avatars
-- Note: Run this through the Supabase SQL Editor if not using CLI
insert into storage.buckets (id, name, public) values ('avatars', 'avatars', true);

-- Storage policies for avatars
create policy "Avatar images are publicly accessible" on storage.objects
  for select using (bucket_id = 'avatars');

create policy "Users can upload their own avatar" on storage.objects
  for insert with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "Users can update their own avatar" on storage.objects
  for update using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "Users can delete their own avatar" on storage.objects
  for delete using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
