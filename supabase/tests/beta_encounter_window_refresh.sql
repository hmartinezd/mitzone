-- Fully migrated disposable LOCAL mitzone_test_* database only. No live fixtures.
begin;
do $$ begin
  if current_database() not like 'mitzone_test_%'
    or (inet_server_addr() is not null and inet_server_addr() not in ('127.0.0.1'::inet,'::1'::inet)) then
    raise exception 'Disposable local mitzone_test_* database required';
  end if;
end $$;
create function pg_temp.assert_true(value boolean, label text) returns void
language plpgsql as $$ begin
  if value is distinct from true then raise exception 'assertion failed: %',label; end if;
end $$;
create function pg_temp.assert_unavailable(statement text) returns void language plpgsql as $$
declare denied boolean := false; begin
  begin execute statement; exception when raise_exception then denied:=true; end;
  if not denied then raise exception 'expected unavailable interaction'; end if;
end $$;

insert into auth.users(id) values
 ('00000000-0000-0000-0000-000000000101'),('00000000-0000-0000-0000-000000000102'),
 ('00000000-0000-0000-0000-000000000103'),('00000000-0000-0000-0000-000000000104'),
 ('00000000-0000-0000-0000-000000000105');
insert into public.profiles(id,display_name) values
 ('00000000-0000-0000-0000-000000000101','Fixture A'),('00000000-0000-0000-0000-000000000102','Fixture B'),
 ('00000000-0000-0000-0000-000000000103','Fixture C');
insert into public.encounters(id,user_a,user_b,context_id,overlap_start,overlap_end) values
 ('00000000-0000-0000-0000-000000000201','00000000-0000-0000-0000-000000000101','00000000-0000-0000-0000-000000000102','fixture:six-days',now()-interval '6 days 10 minutes',now()-interval '6 days'),
 ('00000000-0000-0000-0000-000000000202','00000000-0000-0000-0000-000000000101','00000000-0000-0000-0000-000000000103','fixture:eight-days',now()-interval '8 days 10 minutes',now()-interval '8 days'),
 ('00000000-0000-0000-0000-000000000203','00000000-0000-0000-0000-000000000101','00000000-0000-0000-0000-000000000104','fixture:boundary',now()-interval '7 days 10 minutes',now()-interval '7 days'),
 ('00000000-0000-0000-0000-000000000204','00000000-0000-0000-0000-000000000101','00000000-0000-0000-0000-000000000105','fixture:invalid-future',now(),now()+interval '1 minute');
insert into public.connection_requests(id,sender_user_id,recipient_user_id,encounter_id) values
 ('00000000-0000-0000-0000-000000000301','00000000-0000-0000-0000-000000000101','00000000-0000-0000-0000-000000000103','00000000-0000-0000-0000-000000000202');

set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000101',true);
select pg_temp.assert_true((select count(*)=1 from public.encounters),'only six-day observation is actionable');
select pg_temp.assert_true((select count(*)=1 from public.get_public_profiles(array['00000000-0000-0000-0000-000000000102','00000000-0000-0000-0000-000000000103']::uuid[])), 'expired request does not expose profile');
select set_config('mitzone_test.request_id',(public.send_connection_request('00000000-0000-0000-0000-000000000102','00000000-0000-0000-0000-000000000201')).id::text,true);
select pg_temp.assert_unavailable($q$select public.send_connection_request('00000000-0000-0000-0000-000000000103','00000000-0000-0000-0000-000000000202')$q$);
select pg_temp.assert_unavailable($q$select public.send_connection_request('00000000-0000-0000-0000-000000000104','00000000-0000-0000-0000-000000000203')$q$);
select pg_temp.assert_unavailable($q$select public.send_connection_request('00000000-0000-0000-0000-000000000105','00000000-0000-0000-0000-000000000204')$q$);
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000103',true);
select pg_temp.assert_unavailable($q$select public.accept_connection_request('00000000-0000-0000-0000-000000000301')$q$);
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000102',true);
select public.accept_connection_request(current_setting('mitzone_test.request_id')::uuid);
select pg_temp.assert_true((select count(*)=1 from public.connections),'six-day mutual acceptance works');
insert into public.blocks(blocker_user_id,blocked_user_id) values('00000000-0000-0000-0000-000000000102','00000000-0000-0000-0000-000000000101');
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000101',true);
select pg_temp.assert_true((select count(*)=0 from public.encounters),'other participant block hides encounter symmetrically');
select pg_temp.assert_true((select count(*)=0 from public.get_public_profiles(array['00000000-0000-0000-0000-000000000102']::uuid[])), 'other participant block hides profile');
reset role;
delete from public.blocks;

-- Seed an observed ten-minute session with a recent refresh and original expiry.
insert into public.presence_evidence(id,subject_user_id,context_id,observed_start,observed_end,source,consent_scope,expires_at) values
 ('00000000-0000-0000-0000-000000000401','00000000-0000-0000-0000-000000000101','cell:100:100',now()-interval '10 minutes',now()-interval '30 seconds','geolocation','foreground-explicit',now()+interval '20 minutes'),
 ('00000000-0000-0000-0000-000000000402','00000000-0000-0000-0000-000000000102','cell:100:100',now()-interval '10 minutes',now(),'geolocation','foreground-explicit',now()+interval '20 minutes');
set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000101',true);
select public.refresh_foreground_presence('00000000-0000-0000-0000-000000000401',1,1);
select pg_temp.assert_true((select observed_start=now()-interval '10 minutes' and observed_end>=now() and observed_end<=clock_timestamp() and expires_at=now()+interval '20 minutes' from public.presence_evidence), 'refresh preserves start and original expiry');
select pg_temp.assert_true((select count(*)=1 from public.encounters where context_id='cell:100:100'), 'contiguous shared observation derives encounter');
reset role;
update public.presence_evidence set observed_end=now()-interval '2 minutes' where subject_user_id='00000000-0000-0000-0000-000000000101';
set local role authenticated;
select public.refresh_foreground_presence('00000000-0000-0000-0000-000000000401',1,1);
select pg_temp.assert_true((select observed_start>=now() and observed_start<=clock_timestamp() and observed_end>=now() and observed_end<=clock_timestamp() and expires_at=now()+interval '20 minutes' from public.presence_evidence), 'gap over ninety seconds cannot invent continuous overlap');
select public.refresh_foreground_presence('00000000-0000-0000-0000-000000000401',2,2);
select pg_temp.assert_true((select count(*)=1 and bool_and(context_id='cell:200:200' and observed_start>=now() and observed_start<=clock_timestamp()) from public.presence_evidence), 'movement resets context without bridging old visit');
select public.stop_foreground_presence();
select pg_temp.assert_true((select count(*)=0 from public.presence_evidence), 'Stop removes refreshed observation');
select pg_temp.assert_unavailable($q$select public.refresh_foreground_presence('00000000-0000-0000-0000-000000000401',1,1)$q$);
select public.record_foreground_presence(1,1);
select pg_temp.assert_unavailable($q$select public.refresh_foreground_presence('00000000-0000-0000-0000-000000000401',1,1)$q$);
select pg_temp.assert_true((select count(*)=1 and bool_and(id<>'00000000-0000-0000-0000-000000000401') from public.presence_evidence), 'old refresh cannot change a fresh activation');
rollback;
