-- Profiles contain private fields (languages, interests, and connection goal).
-- Cross-user reads must go through get_public_profiles, not the base table.
drop policy if exists "profiles are publicly readable" on public.profiles;

create policy "users read own profile"
  on public.profiles
  for select
  to authenticated
  using (auth.uid() = id);
