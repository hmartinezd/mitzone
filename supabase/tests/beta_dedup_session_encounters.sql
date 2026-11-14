-- Run only against a fully migrated disposable LOCAL mitzone_test_* database.
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
insert into auth.users(id) values
 ('00000000-0000-0000-0000-000000000501'),
 ('00000000-0000-0000-0000-000000000502');
insert into public.presence_evidence
 (id,subject_user_id,context_id,observed_start,observed_end,source,consent_scope,expires_at)
values
 ('00000000-0000-0000-0000-000000000511','00000000-0000-0000-0000-000000000501',
  'cell:100:100',now()-interval '10 minutes',now()-interval '2 minutes','geolocation','foreground-explicit',now()+interval '20 minutes'),
 ('00000000-0000-0000-0000-000000000512','00000000-0000-0000-0000-000000000502',
  'cell:100:101',now()-interval '9 minutes',now()-interval '1 minute','geolocation','foreground-explicit',now()+interval '20 minutes');
set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000501',true);
select public.process_presence_evidence('00000000-0000-0000-0000-000000000511');
select pg_temp.assert_true((select count(*)=1 from public.encounters),'first shared segment creates one encounter');
select set_config('mitzone_test.encounter_id',(select id::text from public.encounters),true);
select pg_temp.assert_true((select context_id='cell:100:100~nearby' from public.encounters),'neighbor context is canonical');
reset role;
update public.presence_evidence set observed_end=now()
  where id='00000000-0000-0000-0000-000000000511';
set local role authenticated;
select public.process_presence_evidence('00000000-0000-0000-0000-000000000511');
select pg_temp.assert_true((select count(*)=1 and bool_and(id=current_setting('mitzone_test.encounter_id')::uuid)
  and bool_and(overlap_end=now()-interval '1 minute') from public.encounters),
  'refresh updates overlap end while retaining encounter identity');
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000502',true);
select public.process_presence_evidence('00000000-0000-0000-0000-000000000512');
select pg_temp.assert_true((select count(*)=1 from public.encounters),
  'processing from the other neighboring cell cannot create a duplicate');

-- A real observation gap resets the segment start even if the evidence lease
-- UUID remains the same. It must not extend or merge the prior shared visit.
reset role;
update public.presence_evidence set observed_start=now()-interval '6 minutes',observed_end=now()
  where id='00000000-0000-0000-0000-000000000511';
update public.presence_evidence set observed_end=now()
  where id='00000000-0000-0000-0000-000000000512';
set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000501',true);
select public.process_presence_evidence('00000000-0000-0000-0000-000000000511');
select pg_temp.assert_true((select count(*)=2 from public.encounters),
  'new observed segment produces a separate encounter');
select pg_temp.assert_true((select overlap_end=now()-interval '1 minute' from public.encounters
  where id=current_setting('mitzone_test.encounter_id')::uuid),
  'new segment never advances the historical encounter');

-- Movement changes both context and segment start; opposite-side processing
-- still converges on the same new canonical encounter instead of duplicating it.
reset role;
update public.presence_evidence set context_id='cell:101:101',
  observed_start=now()-interval '5 minutes',observed_end=now()
  where id='00000000-0000-0000-0000-000000000511';
set local role authenticated;
select public.process_presence_evidence('00000000-0000-0000-0000-000000000511');
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000502',true);
select public.process_presence_evidence('00000000-0000-0000-0000-000000000512');
select pg_temp.assert_true((select count(*)=3 from public.encounters),
  'movement is a new segment, not duplicate rows from each caller');

-- Existing requests must retain their original FK target as overlap advances.
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000501',true);
select set_config('mitzone_test.request_id',(public.send_connection_request(
 '00000000-0000-0000-0000-000000000502',current_setting('mitzone_test.encounter_id')::uuid)).id::text,true);
select public.process_presence_evidence('00000000-0000-0000-0000-000000000511');
select pg_temp.assert_true((select encounter_id=current_setting('mitzone_test.encounter_id')::uuid
  from public.connection_requests where id=current_setting('mitzone_test.request_id')::uuid),
  'refresh preserves existing relationship FK target');

-- Processing is not an alternate endpoint for reading symmetrically blocked
-- historical rows through SECURITY DEFINER.
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000502',true);
insert into public.blocks(blocker_user_id,blocked_user_id)
 values('00000000-0000-0000-0000-000000000502','00000000-0000-0000-0000-000000000501');
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000501',true);
select pg_temp.assert_true((select count(*)=0 from public.process_presence_evidence('00000000-0000-0000-0000-000000000511')),
  'processing cannot return blocked historical encounters');
rollback;
