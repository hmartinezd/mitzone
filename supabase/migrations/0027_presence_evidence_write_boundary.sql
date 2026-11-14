-- Raw evidence is owner-readable, but only secured server commands may write it.
-- Owner-only RLS alone allowed a client to invent context, timing and consent.
revoke all on table public.presence_evidence from public, anon, authenticated;
grant select on table public.presence_evidence to authenticated;
drop policy if exists "users manage own evidence" on public.presence_evidence;
create policy "users read own evidence" on public.presence_evidence
  for select to authenticated using (auth.uid() = subject_user_id);

-- Stop must be able to delete an observation after it contributed to an
-- encounter. Retain the already-derived social context, not its raw evidence.
alter table public.encounters
  drop constraint if exists encounters_evidence_a_id_fkey,
  drop constraint if exists encounters_evidence_b_id_fkey;
alter table public.encounters
  add constraint encounters_evidence_a_id_fkey
    foreign key (evidence_a_id) references public.presence_evidence(id)
    on delete set null,
  add constraint encounters_evidence_b_id_fkey
    foreign key (evidence_b_id) references public.presence_evidence(id)
    on delete set null;
