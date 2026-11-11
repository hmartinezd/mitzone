-- Historical conversations remain attached to their original relationship.
-- Termination is permanent; a new mutual-consent cycle gets a new row/ID.
alter table public.connections add column terminated_at timestamptz;
alter table public.connection_requests add column invalidated_at timestamptz;
alter table public.connections drop constraint connections_user_a_id_user_b_id_key;
create unique index connections_active_pair_unique
  on public.connections(user_a_id, user_b_id) where terminated_at is null;

create function public.lock_relationship_pair(a uuid, b uuid) returns void
language sql set search_path = public, pg_temp as $$
  select pg_advisory_xact_lock(hashtextextended(least(a,b)::text || ':' || greatest(a,b)::text, 0));
$$;
revoke all on function public.lock_relationship_pair(uuid,uuid) from public;

create function public.terminate_blocked_relationship() returns trigger
language plpgsql security definer set search_path = public, pg_temp as $$
declare a uuid; b uuid;
begin
  if TG_OP = 'DELETE' then a := OLD.blocker_user_id; b := OLD.blocked_user_id;
  else a := NEW.blocker_user_id; b := NEW.blocked_user_id; end if;
  perform lock_relationship_pair(a,b);
  update connections set terminated_at = now()
    where user_a_id = least(a,b) and user_b_id = greatest(a,b) and terminated_at is null;
  update connection_requests set invalidated_at = now()
    where invalidated_at is null and
      ((sender_user_id=a and recipient_user_id=b) or (sender_user_id=b and recipient_user_id=a));
  if TG_OP = 'DELETE' then return OLD; end if;
  return NEW;
end;
$$;
revoke all on function public.terminate_blocked_relationship() from public;
create trigger terminate_relationship_on_block
  before insert or update or delete on public.blocks
  for each row execute function public.terminate_blocked_relationship();

-- Repair relationships hidden by existing blocks before this migration.
update public.connections c set terminated_at = now()
where terminated_at is null and exists(select 1 from public.blocks b
  where (b.blocker_user_id=c.user_a_id and b.blocked_user_id=c.user_b_id)
     or (b.blocker_user_id=c.user_b_id and b.blocked_user_id=c.user_a_id));
update public.connection_requests r set invalidated_at = now()
where invalidated_at is null and exists(select 1 from public.blocks b
  where (b.blocker_user_id=r.sender_user_id and b.blocked_user_id=r.recipient_user_id)
     or (b.blocker_user_id=r.recipient_user_id and b.blocked_user_id=r.sender_user_id));

-- Security-definer avoids directional block RLS obscuring the other user's block.
create function public.can_access_connection(p_connection_id uuid) returns boolean
language sql stable security definer set search_path = public, pg_temp as $$
  select exists(select 1 from connections c where c.id=p_connection_id
    and c.terminated_at is null and (auth.uid()=c.user_a_id or auth.uid()=c.user_b_id)
    and not exists(select 1 from blocks b
      where (b.blocker_user_id=c.user_a_id and b.blocked_user_id=c.user_b_id)
         or (b.blocker_user_id=c.user_b_id and b.blocked_user_id=c.user_a_id)));
$$;
revoke all on function public.can_access_connection(uuid) from public;
grant execute on function public.can_access_connection(uuid) to authenticated;

drop policy "eligible participants read connections" on public.connections;
create policy "eligible participants read connections" on public.connections for select to authenticated
  using(public.can_access_connection(id));
drop policy "participants read requests" on public.connection_requests;
create policy "participants read requests" on public.connection_requests for select to authenticated
  using(invalidated_at is null and (auth.uid()=sender_user_id or auth.uid()=recipient_user_id));
drop policy "active participants read conversations" on public.conversations;
create policy "active participants read conversations" on public.conversations for select to authenticated
  using((auth.uid()=user_a_id or auth.uid()=user_b_id) and public.can_access_connection(connection_id));
drop policy "active participants read messages" on public.messages;
create policy "active participants read messages" on public.messages for select to authenticated
  using(exists(select 1 from conversations c where c.id=conversation_id
    and (auth.uid()=c.user_a_id or auth.uid()=c.user_b_id)
    and public.can_access_connection(c.connection_id)));

create or replace function public.accept_connection_request(p_request_id uuid)
returns public.connection_requests language plpgsql security definer set search_path=public,pg_temp as $$
declare r public.connection_requests;
begin
  select * into r from connection_requests where id=p_request_id;
  if not found or auth.uid() is null or r.recipient_user_id<>auth.uid() then raise exception 'request unavailable'; end if;
  perform lock_relationship_pair(r.sender_user_id,r.recipient_user_id);
  select * into r from connection_requests where id=p_request_id and recipient_user_id=auth.uid()
    and status='pending' and invalidated_at is null for update;
  if not found then raise exception 'request unavailable'; end if;
  if not exists(select 1 from encounters e where e.id=r.encounter_id and e.overlap_end>=now()
    and ((e.user_a=r.sender_user_id and e.user_b=r.recipient_user_id)
      or (e.user_b=r.sender_user_id and e.user_a=r.recipient_user_id)))
    or exists(select 1 from blocks b
      where (b.blocker_user_id=r.sender_user_id and b.blocked_user_id=r.recipient_user_id)
         or (b.blocker_user_id=r.recipient_user_id and b.blocked_user_id=r.sender_user_id))
    then raise exception 'request unavailable'; end if;
  update connection_requests set status='accepted',responded_at=now() where id=r.id returning * into r;
  insert into connections(user_a_id,user_b_id,encounter_id,context_id)
    values(least(r.sender_user_id,r.recipient_user_id),greatest(r.sender_user_id,r.recipient_user_id),r.encounter_id,r.context_id)
    on conflict(user_a_id,user_b_id) where terminated_at is null do nothing;
  insert into notifications(recipient_user_id,type,actor_user_id,entity_id,destination)
    values(r.sender_user_id,'connectionAccepted',auth.uid(),r.id::text,'/app/matches') on conflict do nothing;
  return r;
end;
$$;

create or replace function public.send_connection_request(p_other_user_id uuid,p_encounter_id uuid)
returns public.connection_requests language plpgsql security definer set search_path=public,pg_temp as $$
declare old public.connection_requests; result public.connection_requests;
begin
  if auth.uid() is null or auth.uid()=p_other_user_id then raise exception 'unauthorized'; end if;
  perform lock_relationship_pair(auth.uid(),p_other_user_id);
  if not exists(select 1 from encounters e where e.id=p_encounter_id and e.overlap_end>=now()
    and ((e.user_a=auth.uid() and e.user_b=p_other_user_id) or (e.user_b=auth.uid() and e.user_a=p_other_user_id)))
    then raise exception 'encounter unavailable'; end if;
  if exists(select 1 from blocks b
    where (b.blocker_user_id=auth.uid() and b.blocked_user_id=p_other_user_id)
       or (b.blocker_user_id=p_other_user_id and b.blocked_user_id=auth.uid())) then raise exception 'blocked'; end if;
  if exists(select 1 from connections where user_a_id=least(auth.uid(),p_other_user_id)
    and user_b_id=greatest(auth.uid(),p_other_user_id) and terminated_at is null) then raise exception 'already connected'; end if;
  select * into old from connection_requests where status='pending' and invalidated_at is null
    and ((sender_user_id=auth.uid() and recipient_user_id=p_other_user_id)
      or (sender_user_id=p_other_user_id and recipient_user_id=auth.uid())) order by created_at limit 1 for update;
  if old.id is not null then
    if old.sender_user_id=p_other_user_id then return accept_connection_request(old.id); end if;
    return old;
  end if;
  insert into connection_requests(sender_user_id,recipient_user_id,encounter_id)
    values(auth.uid(),p_other_user_id,p_encounter_id) returning * into result;
  insert into notifications(recipient_user_id,type,actor_user_id,entity_id,destination)
    values(p_other_user_id,'connectionRequest',auth.uid(),result.id::text,'/app/matches') on conflict do nothing;
  return result;
end;
$$;

create or replace function public.decline_connection_request(p_request_id uuid)
returns public.connection_requests language plpgsql security definer set search_path=public,pg_temp as $$
declare r public.connection_requests;
begin
  select * into r from connection_requests where id=p_request_id;
  if not found or auth.uid() is null or r.recipient_user_id<>auth.uid() then raise exception 'request unavailable'; end if;
  perform lock_relationship_pair(r.sender_user_id,r.recipient_user_id);
  if exists(select 1 from blocks where
    (blocker_user_id=r.sender_user_id and blocked_user_id=r.recipient_user_id) or
    (blocker_user_id=r.recipient_user_id and blocked_user_id=r.sender_user_id)) then raise exception 'request unavailable'; end if;
  update connection_requests set status='declined',responded_at=now()
    where id=p_request_id and recipient_user_id=auth.uid() and status='pending' and invalidated_at is null returning * into r;
  if not found then raise exception 'request unavailable'; end if;
  return r;
end;
$$;

create or replace function public.remove_connection(p_connection_id uuid) returns void
language plpgsql security definer set search_path=public,pg_temp as $$
declare c public.connections;
begin
  select * into c from connections where id=p_connection_id;
  if not found or auth.uid() is null or (auth.uid()<>c.user_a_id and auth.uid()<>c.user_b_id) then raise exception 'connection unavailable'; end if;
  perform lock_relationship_pair(c.user_a_id,c.user_b_id);
  update connections set terminated_at=now() where id=c.id and terminated_at is null;
  if not found then raise exception 'connection unavailable'; end if;
  update connection_requests set invalidated_at=now() where invalidated_at is null and status='accepted'
    and ((sender_user_id=c.user_a_id and recipient_user_id=c.user_b_id) or (sender_user_id=c.user_b_id and recipient_user_id=c.user_a_id));
end;
$$;

create or replace function public.get_relationship_state(p_other_user_id uuid,p_encounter_id uuid default null)
returns text language plpgsql security definer set search_path=public,pg_temp as $$
declare me uuid:=auth.uid(); state text;
begin
  if me is null or me=p_other_user_id then raise exception 'unauthorized'; end if;
  if exists(select 1 from blocks where (blocker_user_id=me and blocked_user_id=p_other_user_id)
    or (blocker_user_id=p_other_user_id and blocked_user_id=me)) then return 'blocked'; end if;
  if exists(select 1 from connections where user_a_id=least(me,p_other_user_id)
    and user_b_id=greatest(me,p_other_user_id) and terminated_at is null) then return 'connected'; end if;
  select case when sender_user_id=me then 'outgoingPending' else 'incomingPending' end into state
    from connection_requests where status='pending' and invalidated_at is null
      and ((sender_user_id=me and recipient_user_id=p_other_user_id) or (sender_user_id=p_other_user_id and recipient_user_id=me))
      and (p_encounter_id is null or encounter_id=p_encounter_id) order by created_at desc limit 1;
  return coalesce(state,'none');
end;
$$;

create or replace function public.get_or_create_conversation(p_connection_id uuid) returns public.conversations
language plpgsql security definer set search_path=public,pg_temp as $$
declare c public.connections; result public.conversations;
begin
  select * into c from connections where id=p_connection_id;
  if not found then raise exception 'connection unavailable'; end if;
  perform lock_relationship_pair(c.user_a_id,c.user_b_id);
  if not can_access_connection(c.id) then raise exception 'connection unavailable'; end if;
  select * into result from conversations where connection_id=c.id;
  if result.id is null then
    insert into conversations(connection_id,user_a_id,user_b_id) values(c.id,c.user_a_id,c.user_b_id) returning * into result;
  end if;
  return result;
end;
$$;

create or replace function public.get_conversation_messages(p_conversation_id uuid) returns setof public.messages
language plpgsql security definer set search_path=public,pg_temp as $$
declare c public.conversations;
begin
  select * into c from conversations where id=p_conversation_id;
  if not found then raise exception 'conversation unavailable'; end if;
  perform lock_relationship_pair(c.user_a_id,c.user_b_id);
  if not can_access_connection(c.connection_id) then raise exception 'conversation unavailable'; end if;
  return query select * from messages where conversation_id=c.id order by created_at;
end;
$$;

create or replace function public.send_message(p_conversation_id uuid,p_body text,p_client_message_id text)
returns public.messages language plpgsql security definer set search_path=public,pg_temp as $$
declare c public.conversations; existing public.messages; result public.messages;
begin
  if auth.uid() is null or char_length(trim(p_body))=0 or char_length(p_body)>2000 then raise exception 'invalid message'; end if;
  select * into c from conversations where id=p_conversation_id;
  if not found then raise exception 'conversation unavailable'; end if;
  perform lock_relationship_pair(c.user_a_id,c.user_b_id);
  if not can_access_connection(c.connection_id) then raise exception 'conversation unavailable'; end if;
  select * into existing from messages where sender_user_id=auth.uid() and client_message_id=p_client_message_id;
  if existing.id is not null then
    if existing.conversation_id<>c.id then raise exception 'message identifier belongs to another conversation'; end if;
    return existing;
  end if;
  insert into messages(conversation_id,sender_user_id,body,client_message_id)
    values(c.id,auth.uid(),trim(p_body),p_client_message_id) returning * into result;
  update conversations set last_message_at=result.created_at where id=c.id;
  insert into notifications(recipient_user_id,type,actor_user_id,entity_id,destination)
    values(case when c.user_a_id=auth.uid() then c.user_b_id else c.user_a_id end,'newMessage',auth.uid(),c.id::text,'/app/chat/'||c.id::text) on conflict do nothing;
  return result;
end;
$$;
