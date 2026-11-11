-- Local fixture test of the Data API ACL boundary, not hosted/API/auth proof.
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
create function pg_temp.assert_denied(statement text) returns void language plpgsql as $$
declare actual_state text; begin
  begin execute statement;
  exception when others then get stacked diagnostics actual_state=returned_sqlstate;
  end;
  if actual_state is distinct from '42501' then
    raise exception 'expected permission denial, received %',coalesce(actual_state,'success');
  end if;
end $$;

-- Strict harness proves automatic RLS and the real residual Dxtm defaults
-- independently. Migration0031 must remove those dangerous privileges from
-- every application table; this temporary probe is not an application table.
create table public.local_test_privilege_probe(id integer);
do $$ begin
  if exists(select 1 from pg_event_trigger where evtname='local_test_auto_rls' and evtenabled='O') then
    perform pg_temp.assert_true((select relrowsecurity from pg_class
      where oid='public.local_test_privilege_probe'::regclass),'automatic RLS is enabled');
    perform pg_temp.assert_true(not has_table_privilege('authenticated','public.local_test_privilege_probe','SELECT'), 'strict model has no SELECT default');
    perform pg_temp.assert_true(has_table_privilege('authenticated','public.local_test_privilege_probe','TRUNCATE'), 'strict model accurately includes residual TRUNCATE default');
  end if;
end $$;
do $$ declare relation text; actor text; privilege text; begin
  foreach relation in array array['profiles','presence_evidence','event_participation','reports',
    'encounters','connection_requests','connections','conversations','messages','blocks',
    'personality_profiles','notifications','device_tokens'] loop
    foreach actor in array array['anon','authenticated','service_role'] loop
      foreach privilege in array array['TRUNCATE','REFERENCES','TRIGGER','MAINTAIN'] loop
        perform pg_temp.assert_true(not has_table_privilege(actor,'public.'||relation,privilege),
          actor||' must not have '||privilege||' on '||relation);
      end loop;
    end loop;
    foreach privilege in array array['SELECT','INSERT','UPDATE','DELETE'] loop
      perform pg_temp.assert_true(not has_table_privilege('anon','public.'||relation,privilege),
        'anonymous table access is not granted: '||relation||'/'||privilege);
    end loop;
  end loop;
end $$;
select pg_temp.assert_true(not has_table_privilege('authenticated','public.messages','SELECT'), 'no direct message-table read grant');
select pg_temp.assert_true(not has_table_privilege('authenticated','public.presence_evidence','INSERT'), 'no client evidence insert grant');
select pg_temp.assert_true(not has_table_privilege('authenticated','public.presence_evidence','UPDATE'), 'no client evidence update grant');
select pg_temp.assert_true(not has_table_privilege('authenticated','public.presence_evidence','DELETE'), 'no client evidence delete grant');
select pg_temp.assert_true(has_column_privilege('authenticated','public.notifications','read_at','UPDATE'), 'read status update explicitly granted');
select pg_temp.assert_true(not has_column_privilege('authenticated','public.notifications','destination','UPDATE'), 'notification destination cannot be rewritten');
select pg_temp.assert_true(not has_function_privilege('anon','public.record_foreground_presence(double precision,double precision)','EXECUTE'), 'anonymous activation RPC is denied');
select pg_temp.assert_true(not has_function_privilege('anon','public.refresh_foreground_presence(uuid,double precision,double precision)','EXECUTE'), 'anonymous refresh RPC is denied');
select pg_temp.assert_true(not has_function_privilege('anon','public.send_message(uuid,text,text)','EXECUTE'), 'anonymous chat RPC is denied');
select pg_temp.assert_true(not has_function_privilege('anon','public.lock_relationship_pair(uuid,uuid)','EXECUTE')
  and not has_function_privilege('authenticated','public.lock_relationship_pair(uuid,uuid)','EXECUTE'), 'relationship lock helper is internal-only');

insert into auth.users(id) values
 ('00000000-0000-0000-0000-000000000901'),('00000000-0000-0000-0000-000000000902');
insert into public.encounters(id,user_a,user_b,context_id,overlap_start,overlap_end) values
 ('00000000-0000-0000-0000-000000000911','00000000-0000-0000-0000-000000000901','00000000-0000-0000-0000-000000000902',
  'fixture:explicit-privileges',now()-interval '6 minutes',now()-interval '1 minute');
insert into public.notifications(id,recipient_user_id,type) values
 ('00000000-0000-0000-0000-000000000921','00000000-0000-0000-0000-000000000901','connectionRequest'),
 ('00000000-0000-0000-0000-000000000922','00000000-0000-0000-0000-000000000902','connectionRequest');

set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000901',true);
insert into public.profiles(id,display_name) values(auth.uid(),'ACL fixture A');
update public.profiles set display_name='ACL fixture A updated' where id=auth.uid();
select pg_temp.assert_true((select count(*)=1 from public.profiles),'profile grants retained');
insert into public.personality_profiles(user_id,traits,questionnaire_version,completed_at,visibility)
 values(auth.uid(),'{}',1,now(),'private') on conflict(user_id) do update set traits=excluded.traits;
update public.personality_profiles set visibility='matching' where user_id=auth.uid();
select pg_temp.assert_true((select visibility='matching' from public.personality_profiles),'personality read/write grants work');
insert into public.device_tokens(user_id,token,platform,updated_at,last_seen_at)
 values(auth.uid(),'fixture-token-a','ios',now(),now()) on conflict(token) do update
 set user_id=excluded.user_id,platform=excluded.platform,updated_at=excluded.updated_at,last_seen_at=excluded.last_seen_at;
insert into public.device_tokens(user_id,token,platform,updated_at,last_seen_at)
 values(auth.uid(),'fixture-token-a','ios',now(),now()) on conflict(token) do update
 set user_id=excluded.user_id,platform=excluded.platform,updated_at=excluded.updated_at,last_seen_at=excluded.last_seen_at;
select pg_temp.assert_true((select count(*)=1 from public.device_tokens),'device-token upsert grants work');
update public.notifications set read_at=now() where id='00000000-0000-0000-0000-000000000921' and recipient_user_id=auth.uid();
select pg_temp.assert_true((select count(*)=1 and bool_and(read_at is not null) from public.notifications),'owner notification read/update works');
select pg_temp.assert_denied($q$update public.notifications set destination='/forged'$q$);
select pg_temp.assert_true((select count(*)=1 from public.encounters),'encounter feed read works');
select set_config('mitzone_test.acl_request',(public.send_connection_request(
 '00000000-0000-0000-0000-000000000902','00000000-0000-0000-0000-000000000911')).id::text,true);
select pg_temp.assert_true((select count(*)=1 from public.connection_requests),'request feed read works');
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000902',true);
select pg_temp.assert_true((select count(*)=0 from public.personality_profiles),'other user cannot read raw traits');
select pg_temp.assert_true((select count(*)=0 from public.device_tokens),'other user cannot read tokens');
select pg_temp.assert_denied($q$insert into public.device_tokens(user_id,token,platform,updated_at,last_seen_at)
 values(auth.uid(),'fixture-token-a','ios',now(),now()) on conflict(token) do update set user_id=excluded.user_id$q$);
select public.accept_connection_request(current_setting('mitzone_test.acl_request')::uuid);
select set_config('mitzone_test.acl_connection',(select id::text from public.connections),true);
select set_config('mitzone_test.acl_conversation',(public.get_or_create_conversation(
 current_setting('mitzone_test.acl_connection')::uuid)).id::text,true);
select pg_temp.assert_true((select count(*)=1 from public.conversations),'conversation list read works');
select public.send_message(current_setting('mitzone_test.acl_conversation')::uuid,'Fixture message','acl-message-1');
select pg_temp.assert_true((select count(*)=1 from public.get_conversation_messages(
 current_setting('mitzone_test.acl_conversation')::uuid)), 'chat RPC works without message-table grants');
select pg_temp.assert_denied('select * from public.messages');
select pg_temp.assert_denied('truncate public.messages');

-- Existing block upsert + delete paths require UPDATE as well as INSERT.
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000901',true);
insert into public.blocks(blocker_user_id,blocked_user_id) values(auth.uid(),'00000000-0000-0000-0000-000000000902')
 on conflict(blocker_user_id,blocked_user_id) do update set blocked_user_id=excluded.blocked_user_id;
insert into public.blocks(blocker_user_id,blocked_user_id) values(auth.uid(),'00000000-0000-0000-0000-000000000902')
 on conflict(blocker_user_id,blocked_user_id) do update set blocked_user_id=excluded.blocked_user_id;
select pg_temp.assert_true((select count(*)=1 from public.blocks),'block list and repeated upsert work');
delete from public.blocks where blocker_user_id=auth.uid();
select pg_temp.assert_true((select count(*)=0 from public.blocks),'unblock delete grant works');
delete from public.device_tokens where user_id=auth.uid() and token='fixture-token-a';
select pg_temp.assert_true((select count(*)=0 from public.device_tokens),'token removal grant works');
insert into public.reports(reporter_user_id,reported_user_id,reason)
 values(auth.uid(),'00000000-0000-0000-0000-000000000902','spam');
select pg_temp.assert_denied('select * from public.reports');
select pg_temp.assert_denied('truncate public.profiles');
select pg_temp.assert_denied('truncate public.presence_evidence');
set local role anon;
select pg_temp.assert_denied('select * from public.encounters');
select pg_temp.assert_denied('truncate public.reports');
reset role;
rollback;
