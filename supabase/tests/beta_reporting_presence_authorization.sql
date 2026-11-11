-- Run only in a disposable, fully migrated LOCAL database named mitzone_test_*.
-- All fixture data and temporary helper functions are rolled back.
begin;
do $$ begin
  if current_database() not like 'mitzone_test_%'
    or (inet_server_addr() is not null and inet_server_addr() not in ('127.0.0.1'::inet, '::1'::inet)) then
    raise exception 'This regression test requires a disposable local mitzone_test_* database';
  end if;
end $$;

create function pg_temp.assert_true(value boolean, label text) returns void
language plpgsql as $$ begin
  if value is distinct from true then raise exception 'assertion failed: %', label; end if;
end $$;
create function pg_temp.assert_error(statement text, expected_state text) returns void
language plpgsql as $$ declare actual_state text; begin
  begin execute statement;
  exception when others then get stacked diagnostics actual_state = returned_sqlstate;
  end;
  if actual_state is distinct from expected_state then
    raise exception 'expected SQLSTATE %, received %', expected_state, coalesce(actual_state, 'success');
  end if;
end $$;

insert into auth.users(id) values
  ('00000000-0000-0000-0000-000000000101'),
  ('00000000-0000-0000-0000-000000000102'),
  ('00000000-0000-0000-0000-000000000103');

-- Fixture evidence is inserted by the database owner, never a client fallback.
insert into public.presence_evidence
  (id, subject_user_id, context_id, observed_start, observed_end, source, consent_scope, expires_at)
values
  ('00000000-0000-0000-0000-000000000111', '00000000-0000-0000-0000-000000000101',
   'cell:100:100', now() - interval '10 minutes', now(), 'geolocation', 'foreground-explicit', now() + interval '30 minutes'),
  ('00000000-0000-0000-0000-000000000112', '00000000-0000-0000-0000-000000000102',
   'cell:100:100', now() - interval '10 minutes', now(), 'geolocation', 'foreground-explicit', now() + interval '30 minutes');
insert into public.encounters
  (id,user_a,user_b,context_id,overlap_start,overlap_end,evidence_a_id,evidence_b_id)
values
  ('00000000-0000-0000-0000-000000000121', '00000000-0000-0000-0000-000000000101',
   '00000000-0000-0000-0000-000000000102', 'cell:100:100', now() - interval '10 minutes', now(),
   '00000000-0000-0000-0000-000000000111', '00000000-0000-0000-0000-000000000112');

set local role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000101', true);
-- A normal submit is accepted without SELECT/RETURNING privileges.
insert into public.reports(reporter_user_id,reported_user_id,reason,details)
values ('00000000-0000-0000-0000-000000000101','00000000-0000-0000-0000-000000000102','harassment','test fixture only');
select pg_temp.assert_error($q$select * from public.reports$q$, '42501');
select pg_temp.assert_error($q$update public.reports set details='changed'$q$, '42501');
select pg_temp.assert_error($q$delete from public.reports$q$, '42501');
select pg_temp.assert_error($q$insert into public.reports(reporter_user_id,reported_user_id,reason)
  values ('00000000-0000-0000-0000-000000000102','00000000-0000-0000-0000-000000000103','spam')$q$, '42501');
select pg_temp.assert_error($q$insert into public.reports(reporter_user_id,reported_user_id,reason,created_at)
  values ('00000000-0000-0000-0000-000000000101','00000000-0000-0000-0000-000000000102','spam',now()-interval '1 day')$q$, '42501');
select pg_temp.assert_error($q$insert into public.reports(reporter_user_id,reported_user_id,reason)
  values ('00000000-0000-0000-0000-000000000101','00000000-0000-0000-0000-000000000101','spam')$q$, '23514');
select pg_temp.assert_error($q$insert into public.reports(reporter_user_id,reported_user_id,reason,details)
  values ('00000000-0000-0000-0000-000000000101','00000000-0000-0000-0000-000000000102','spam',repeat('x',501))$q$, '23514');
select pg_temp.assert_error($q$insert into public.reports(reporter_user_id,reported_user_id,reason)
  values ('00000000-0000-0000-0000-000000000101','00000000-0000-0000-0000-000000000102','harassment')$q$, '23505');

-- Report subjects, unrelated users and anonymous callers cannot inspect reports.
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000102', true);
select pg_temp.assert_error($q$select * from public.reports$q$, '42501');
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000103', true);
select pg_temp.assert_error($q$select * from public.reports$q$, '42501');
set local role anon;
select pg_temp.assert_error($q$insert into public.reports(reporter_user_id,reported_user_id,reason)
  values ('00000000-0000-0000-0000-000000000101','00000000-0000-0000-0000-000000000102','spam')$q$, '42501');
select pg_temp.assert_error($q$select * from public.presence_evidence$q$, '42501');

set local role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000101', true);
select pg_temp.assert_true((select count(*)=1 from public.presence_evidence), 'only owner evidence is readable');
select pg_temp.assert_error($q$insert into public.presence_evidence
  (id,subject_user_id,context_id,observed_start,observed_end,source,expires_at)
  values (gen_random_uuid(),auth.uid(),'invented',now(),now(),'geolocation',now()+interval '30 minutes')$q$, '42501');
select pg_temp.assert_error($q$update public.presence_evidence set observed_start=now()-interval '1 day'$q$, '42501');
select pg_temp.assert_error($q$delete from public.presence_evidence$q$, '42501');
-- Secured Stop still works, including when an encounter references the evidence.
select public.stop_foreground_presence();
select pg_temp.assert_true((select count(*)=0 from public.presence_evidence), 'Stop revokes owner evidence');
reset role;
select pg_temp.assert_true((select evidence_a_id is null and evidence_b_id is not null from public.encounters
  where id='00000000-0000-0000-0000-000000000121'), 'Stop clears only revoked evidence reference');
select pg_temp.assert_true((select count(*)=1 from public.presence_evidence), 'Stop preserves other user evidence');
select pg_temp.assert_true((select count(*)=1 from public.reports), 'report persisted once');

set local role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000101', true);
-- The canonical server-owned recording command remains usable after ACL changes.
select public.record_foreground_presence(1.0, 1.0);
select pg_temp.assert_true((select count(*)=1 from public.presence_evidence), 'RPC can record server-owned evidence');
rollback;
