-- Explicit opt-in Data API privileges, independent of platform table defaults.
-- Row-level policies remain the ownership/relationship authorization boundary.
revoke all on table public.profiles, public.presence_evidence,
  public.event_participation, public.reports, public.encounters, public.connection_requests,
  public.connections, public.conversations, public.messages, public.blocks,
  public.personality_profiles, public.notifications, public.device_tokens
  from public, anon, authenticated;

-- Staging's disabled automatic exposure still leaves Dxtm defaults. In
-- particular TRUNCATE bypasses RLS. Remove these privileges on app tables only.
revoke truncate, references, trigger, maintain on table public.profiles,
  public.presence_evidence, public.event_participation, public.reports,
  public.encounters, public.connection_requests, public.connections,
  public.conversations, public.messages, public.blocks, public.personality_profiles,
  public.notifications, public.device_tokens from service_role;

grant select, insert, update on table public.profiles to authenticated;
grant select on table public.presence_evidence to authenticated;
grant select, insert, update, delete on table public.event_participation to authenticated;
grant insert(reporter_user_id,reported_user_id,reason,details)
  on table public.reports to authenticated;

grant select on table public.encounters, public.connection_requests,
  public.connections, public.conversations to authenticated;

-- Block upsert and unblock use existing owner-only RLS and termination triggers.
grant select, delete on table public.blocks to authenticated;
grant insert(blocker_user_id,blocked_user_id),
  update(blocker_user_id,blocked_user_id) on table public.blocks to authenticated;

grant select on table public.personality_profiles to authenticated;
grant insert(user_id,traits,questionnaire_version,completed_at,visibility),
  update(user_id,traits,questionnaire_version,completed_at,visibility)
  on table public.personality_profiles to authenticated;

grant select on table public.notifications to authenticated;
grant update(read_at) on table public.notifications to authenticated;

grant select, delete on table public.device_tokens to authenticated;
grant insert(user_id,token,platform,updated_at,last_seen_at),
  update(user_id,token,platform,updated_at,last_seen_at)
  on table public.device_tokens to authenticated;

-- Deliberately no anonymous table access, direct message-table access or raw
-- presence writes. Chat uses secured RPCs; presence writes use server leases.
-- Push is a separate blocked beta capability. No new service_role grants are
-- introduced here: dispatch-push's block lookup/error handling must be repaired
-- and independently tested before enabling its narrowly scoped operations.
