-- SQL integration evidence only: auth.users/JWT-claim fixtures do not exercise
-- GoTrue, email delivery, mobile permission dialogs or physical presence.
-- Run on a fully migrated disposable LOCAL mitzone_test_* database only.
begin;
do $$ begin
  if current_database() not like 'mitzone_test_%'
    or (inet_server_addr() is not null and inet_server_addr() not in ('127.0.0.1'::inet,'::1'::inet)) then
    raise exception 'Disposable local mitzone_test_* database required';
  end if;
end $$;
create function pg_temp.assert_true(value boolean,label text) returns void
language plpgsql as $$ begin
  if value is distinct from true then raise exception 'assertion failed: %',label; end if;
end $$;
create function pg_temp.assert_error(statement text,expected_state text) returns void
language plpgsql as $$ declare actual_state text; begin
  begin execute statement;
  exception when others then get stacked diagnostics actual_state=returned_sqlstate;
  end;
  if actual_state is distinct from expected_state then
    raise exception 'expected SQLSTATE %, received %',expected_state,coalesce(actual_state,'success');
  end if;
end $$;

insert into auth.users(id) values
 ('00000000-0000-0000-0000-000000000601'),
 ('00000000-0000-0000-0000-000000000602');
set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000601',true);
insert into public.profiles(id,display_name,bio)
 values(auth.uid(),'Journey fixture A','Private owner fixture');
update public.profiles set display_name='Updated fixture A' where id=auth.uid();
select pg_temp.assert_true((select display_name='Updated fixture A' from public.profiles), 'profile owner can save own fields');
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000602',true);
insert into public.profiles(id,display_name) values(auth.uid(),'Journey fixture B');
select pg_temp.assert_true((select count(*)=1 from public.profiles), 'base profile reads exclude the other account');
update public.profiles set display_name='Unauthorized edit' where id='00000000-0000-0000-0000-000000000601';
select pg_temp.assert_true((select count(*)=0 from public.get_public_profiles(array['00000000-0000-0000-0000-000000000601']::uuid[])), 'unrelated profile is not exposed');
select pg_temp.assert_error($q$insert into public.profiles(id,display_name)
 values('00000000-0000-0000-0000-000000000601','Spoofed owner')$q$, '42501');
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000601',true);
select pg_temp.assert_true((select display_name='Updated fixture A' from public.profiles), 'other account cannot edit owner profile');

-- Both users activate via the real secured command. A single fresh observation
-- has zero duration and must not manufacture an instant encounter.
select set_config('mitzone_test.journey_evidence_a',evidence_id::text,true)
 from public.record_foreground_presence(1.0,1.0);
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000602',true);
select set_config('mitzone_test.journey_evidence_b',evidence_id::text,true)
 from public.record_foreground_presence(1.0,1.0);
select pg_temp.assert_true((select count(*)=0 from public.encounters), 'activation alone never fabricates elapsed overlap');
select pg_temp.assert_true((select count(*)=1 from public.presence_evidence), 'each account reads only its own raw evidence');

-- Clearly identified administrator fixture to avoid waiting six real minutes.
-- This is deterministic SQL evidence, not a claim of real-world attendance.
reset role;
update public.presence_evidence
 set observed_start=now()-interval '6 minutes',observed_end=now()-interval '30 seconds'
 where id in(current_setting('mitzone_test.journey_evidence_a')::uuid,
   current_setting('mitzone_test.journey_evidence_b')::uuid);
set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000601',true);
select public.refresh_foreground_presence(current_setting('mitzone_test.journey_evidence_a')::uuid,1.0,1.0);
select pg_temp.assert_true((select count(*)=1 from public.encounters), 'contiguous elapsed fixture produces one encounter');
select set_config('mitzone_test.journey_encounter',(select id::text from public.encounters),true);
select pg_temp.assert_true((select count(*)=1 from public.get_public_profiles(array['00000000-0000-0000-0000-000000000602']::uuid[])), 'eligible encounter permits limited public profile');

select set_config('mitzone_test.journey_request',(public.send_connection_request(
 '00000000-0000-0000-0000-000000000602',current_setting('mitzone_test.journey_encounter')::uuid)).id::text,true);
select pg_temp.assert_true((select count(*)=0 from public.connections), 'request alone does not establish a connection');
select pg_temp.assert_true((public.send_connection_request('00000000-0000-0000-0000-000000000602',
 current_setting('mitzone_test.journey_encounter')::uuid)).id=current_setting('mitzone_test.journey_request')::uuid,
 'request retry is idempotent');
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000602',true);
select public.accept_connection_request(current_setting('mitzone_test.journey_request')::uuid);
select set_config('mitzone_test.journey_connection',(select id::text from public.connections),true);
select set_config('mitzone_test.journey_conversation',(public.get_or_create_conversation(
 current_setting('mitzone_test.journey_connection')::uuid)).id::text,true);

select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000601',true);
select set_config('mitzone_test.journey_message',(public.send_message(
 current_setting('mitzone_test.journey_conversation')::uuid,'Hello from fixture A','journey-a-1')).id::text,true);
select pg_temp.assert_true((public.send_message(current_setting('mitzone_test.journey_conversation')::uuid,
 'Hello from fixture A','journey-a-1')).id=current_setting('mitzone_test.journey_message')::uuid,
 'message retry returns same canonical message');
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000602',true);
select public.send_message(current_setting('mitzone_test.journey_conversation')::uuid,
 'Reply from fixture B','journey-b-1');
select pg_temp.assert_true((select count(*)=2 from public.get_conversation_messages(
 current_setting('mitzone_test.journey_conversation')::uuid)), 'both participants see the two canonical messages');

-- Stop revokes observation collection without terminating existing mutual consent.
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000601',true);
select public.stop_foreground_presence();
select pg_temp.assert_true((select count(*)=0 from public.presence_evidence), 'Stop removes owner lease');
select pg_temp.assert_true((select count(*)=1 from public.connections), 'Stop preserves accepted connection');
select pg_temp.assert_true((select count(*)=2 from public.get_conversation_messages(
 current_setting('mitzone_test.journey_conversation')::uuid)), 'Stop preserves authorized conversation');
select pg_temp.assert_error(format('select public.refresh_foreground_presence(%L,1.0,1.0)',
 current_setting('mitzone_test.journey_evidence_a')), 'P0001');

-- A block from B restricts both parties, not just the user owning the block row.
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000602',true);
insert into public.blocks(blocker_user_id,blocked_user_id)
 values(auth.uid(),'00000000-0000-0000-0000-000000000601');
select pg_temp.assert_true((select count(*)=0 from public.connections), 'blocker cannot read terminated connection');
select pg_temp.assert_error('select * from public.messages', '42501');
select pg_temp.assert_error(format('select public.send_message(%L,%L,%L)',
 current_setting('mitzone_test.journey_conversation'),'denied','journey-b-denied'), 'P0001');
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000601',true);
select pg_temp.assert_true((select count(*)=0 from public.connections), 'blocked account cannot read terminated connection');
select pg_temp.assert_error('select * from public.messages', '42501');
select pg_temp.assert_error(format('select public.get_conversation_messages(%L)',
 current_setting('mitzone_test.journey_conversation')), 'P0001');
select pg_temp.assert_error(format('select public.send_message(%L,%L,%L)',
 current_setting('mitzone_test.journey_conversation'),'denied','journey-a-denied'), 'P0001');

-- Reporting remains available even after blocking. Neither ordinary account
-- receives access to submitted reports or a promised moderation outcome.
insert into public.reports(reporter_user_id,reported_user_id,reason,details)
 values(auth.uid(),'00000000-0000-0000-0000-000000000602','safetyConcern','Deterministic SQL fixture only');
select pg_temp.assert_error('select * from public.reports','42501');
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000602',true);
select pg_temp.assert_error('select * from public.reports','42501');
delete from public.blocks where blocker_user_id=auth.uid();
select pg_temp.assert_true((select count(*)=0 from public.connections), 'unblock does not restore connection');
select pg_temp.assert_error('select * from public.messages', '42501');
select pg_temp.assert_error(format('select public.get_conversation_messages(%L)',
 current_setting('mitzone_test.journey_conversation')), 'P0001');
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000601',true);
select pg_temp.assert_error('select * from public.messages', '42501');
select pg_temp.assert_error(format('select public.get_or_create_conversation(%L)',
 current_setting('mitzone_test.journey_connection')), 'P0001');
reset role;
select pg_temp.assert_true((select count(*)=2 from public.messages), 'history retention is separate from authorization');
select pg_temp.assert_true((select count(*)=1 from public.reports), 'one authenticated report was persisted');
rollback;
