-- RLS remains the authorization boundary for profile rows.
grant usage on schema public to authenticated;
grant select, insert, update on table public.profiles to authenticated;

-- Keep the RPC used for privacy-filtered cross-user profile reads callable by
-- the client role while its security-definer body enforces the boundary.
grant execute on function public.get_public_profiles(uuid[]) to authenticated;