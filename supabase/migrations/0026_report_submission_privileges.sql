-- RLS policies do not grant table privileges. Permit authenticated submission
-- without exposing reports to either party or allowing client-owned timestamps.
revoke all on table public.reports from public, anon, authenticated;
grant insert (reporter_user_id, reported_user_id, reason, details)
  on table public.reports to authenticated;

-- The existing INSERT policy still requires auth.uid() = reporter_user_id.
-- id and created_at remain server defaults; the hourly duplicate limit therefore
-- cannot be bypassed by a client choosing an arbitrary creation time.
