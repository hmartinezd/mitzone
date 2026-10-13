-- Run with psql -v ON_ERROR_STOP=1 against a disposable migrated database.
-- Fixtures are rolled back; never run against a live user's relationship.
begin;
create function pg_temp.assert_true(value boolean, message text) returns void
language plpgsql as $$ begin if value is distinct from true then raise exception 'assertion failed: %', message; end if; end; $$;
create function pg_temp.assert_denied(statement text) returns void language plpgsql as $$
declare denied boolean:=false;
begin
  begin execute statement; exception when raise_exception then denied:=true; end;
  if not denied then raise exception 'expected denial: %',statement; end if;
end; $$;
insert into auth.users(id) values
 ('00000000-0000-0000-0000-000000000001'),
 ('00000000-0000-0000-0000-000000000002'),
 ('00000000-0000-0000-0000-000000000003');
insert into public.encounters(id,user_a,user_b,context_id,overlap_start,overlap_end) values
 ('00000000-0000-0000-0000-000000000010','00000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000002','test:explicit-presence',now()-interval '5 minutes',now()+interval '30 minutes');
set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000001',true);
select id as request_id from send_connection_request('00000000-0000-0000-0000-000000000002','00000000-0000-0000-0000-000000000010') \gset
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000002',true);
select accept_connection_request(:'request_id');
select id as old_connection from connections \gset
select id as old_conversation from get_or_create_conversation(:'old_connection') \gset
select send_message(:'old_conversation','retained private history','old-message-key');
insert into blocks(blocker_user_id,blocked_user_id) values ('00000000-0000-0000-0000-000000000002','00000000-0000-0000-0000-000000000001');
select pg_temp.assert_true((select count(*)=0 from connections),'blocker connections hidden');
select pg_temp.assert_true((select count(*)=0 from conversations),'blocker conversation denied');
select pg_temp.assert_true((select count(*)=0 from messages),'blocker history denied');
select pg_temp.assert_denied(format('select get_conversation_messages(%L)', :'old_conversation'));
select pg_temp.assert_denied(format('select get_or_create_conversation(%L)', :'old_connection'));
select pg_temp.assert_denied(format('select send_message(%L,%L,%L)', :'old_conversation','denied','key-2'));
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000001',true);
select pg_temp.assert_true((select count(*)=0 from connections),'blocked user connections hidden');
select pg_temp.assert_true((select count(*)=0 from conversations),'blocked user conversation denied');
select pg_temp.assert_true((select count(*)=0 from messages),'blocked user history denied');
select pg_temp.assert_true(get_relationship_state('00000000-0000-0000-0000-000000000002')='blocked','symmetric blocked eligibility');
select pg_temp.assert_denied('select send_connection_request(''00000000-0000-0000-0000-000000000002'',''00000000-0000-0000-0000-000000000010'')');
select pg_temp.assert_denied(format('select get_conversation_messages(%L)', :'old_conversation'));
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000002',true);
delete from blocks where blocker_user_id=auth.uid();
select pg_temp.assert_true((select count(*)=0 from connections),'unblock never restores connection');
select pg_temp.assert_true((select count(*)=0 from connection_requests),'unblock never restores accepted request');
select pg_temp.assert_denied(format('select accept_connection_request(%L)', :'request_id'));
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000001',true);
select pg_temp.assert_true(get_relationship_state('00000000-0000-0000-0000-000000000002')='none','fresh consent required');
select pg_temp.assert_true((select count(*)=0 from messages),'unblock never restores history');
select id as new_request from send_connection_request('00000000-0000-0000-0000-000000000002','00000000-0000-0000-0000-000000000010') \gset
select pg_temp.assert_true(:'new_request'<>:'request_id','fresh request identity');
select pg_temp.assert_true((select count(*)=0 from connections),'request alone cannot reconnect');
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000002',true);
select accept_connection_request(:'new_request');
select id as new_connection from connections \gset
select pg_temp.assert_true(:'new_connection'<>:'old_connection','fresh connection identity');
select id as new_conversation from get_or_create_conversation(:'new_connection') \gset
select pg_temp.assert_true(:'new_conversation'<>:'old_conversation','fresh conversation identity');
select pg_temp.assert_true((select count(*)=0 from messages),'new relationship cannot reveal old messages');
select pg_temp.assert_denied(format('select send_message(%L,%L,%L)', :'new_conversation','new content','old-message-key'));
select pg_temp.assert_denied(format('select get_conversation_messages(%L)', :'old_conversation'));
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000001',true);
select pg_temp.assert_denied(format('select get_conversation_messages(%L)', :'old_conversation'));
select pg_temp.assert_denied(format('select send_message(%L,%L,%L)', :'old_conversation','denied','key-3'));
select pg_temp.assert_denied(format('select get_or_create_conversation(%L)', :'old_connection'));
-- Removal also archives the connection rather than cascading through history.
select remove_connection(:'new_connection');
select pg_temp.assert_true((select count(*)=0 from conversations),'removal revokes conversation access');
-- Pending requests are invalidated too, in either block direction.
select id as pending_request from send_connection_request('00000000-0000-0000-0000-000000000002','00000000-0000-0000-0000-000000000010') \gset
insert into blocks(blocker_user_id,blocked_user_id) values ('00000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000002');
delete from blocks where blocker_user_id=auth.uid();
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000002',true);
select pg_temp.assert_denied(format('select accept_connection_request(%L)', :'pending_request'));
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000003',true);
select pg_temp.assert_true((select count(*)=0 from conversations),'unrelated user has no conversation access');
select pg_temp.assert_denied(format('select get_conversation_messages(%L)', :'old_conversation'));
reset role;
select pg_temp.assert_true((select count(*)=2 from connections),'historical connection records retained');
select pg_temp.assert_true((select count(*)=2 from conversations),'historical conversations retained');
select pg_temp.assert_true((select count(*)=1 from messages),'historical messages retained');
select pg_temp.assert_true((select count(*)=0 from connections where terminated_at is null),'no active historical relationship');
rollback;
