-- Remove superseded permissive policies. PostgreSQL combines policies with OR.
drop policy if exists "participants read connections" on public.connections;
drop policy if exists "conversation participants read" on public.conversations;
drop policy if exists "message participants read" on public.messages;

-- Query-backed indexes only: participant/time feeds and conversation message order.
create index if not exists encounters_user_a_overlap_idx
  on public.encounters(user_a, overlap_end desc);
create index if not exists encounters_user_b_overlap_idx
  on public.encounters(user_b, overlap_end desc);
create index if not exists blocks_blocked_user_idx
  on public.blocks(blocked_user_id);
create index if not exists messages_conversation_created_idx
  on public.messages(conversation_id, created_at);
create index if not exists conversations_participant_idx
  on public.conversations(user_a_id, user_b_id);
