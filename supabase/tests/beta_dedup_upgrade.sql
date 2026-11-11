-- Through0029 only; exercise0030 with legacy duplicate rows and real FK anchors.
begin;
do $$ begin
  if current_database() not like 'mitzone_test_%' or inet_server_addr() is not null then
    raise exception 'Disposable local Unix-socket test database required';
  end if;
end $$;
insert into auth.users(id) values
 ('00000000-0000-0000-0000-000000000701'),('00000000-0000-0000-0000-000000000702');
insert into public.presence_evidence(id,subject_user_id,context_id,observed_start,observed_end,source,expires_at) values
 ('00000000-0000-0000-0000-000000000711','00000000-0000-0000-0000-000000000701','cell:100:100',now()-interval '10 minutes',now()-interval '10 seconds','geolocation',now()+interval '20 minutes'),
 ('00000000-0000-0000-0000-000000000712','00000000-0000-0000-0000-000000000702','cell:100:101',now()-interval '9 minutes',now()-interval '10 seconds','geolocation',now()+interval '20 minutes');
insert into public.encounters(id,user_a,user_b,context_id,overlap_start,overlap_end,evidence_a_id,evidence_b_id,created_at) values
 ('00000000-0000-0000-0000-000000000721','00000000-0000-0000-0000-000000000701','00000000-0000-0000-0000-000000000702','cell:100:100~nearby',now()-interval '9 minutes',now()-interval '2 minutes','00000000-0000-0000-0000-000000000711','00000000-0000-0000-0000-000000000712',now()-interval '10 minutes'),
 ('00000000-0000-0000-0000-000000000722','00000000-0000-0000-0000-000000000701','00000000-0000-0000-0000-000000000702','cell:100:101~nearby',now()-interval '9 minutes',now()-interval '1 minute','00000000-0000-0000-0000-000000000711','00000000-0000-0000-0000-000000000712',now()-interval '9 minutes');
insert into public.connection_requests(id,sender_user_id,recipient_user_id,encounter_id) values
 ('00000000-0000-0000-0000-000000000731','00000000-0000-0000-0000-000000000701','00000000-0000-0000-0000-000000000702','00000000-0000-0000-0000-000000000722');
\ir ../migrations/0030_stable_session_encounters.sql
do $$ begin
 if (select count(*) from public.encounters)<>2 then raise exception 'migration deleted history'; end if;
 if (select evidence_a_observed_start from public.encounters where id='00000000-0000-0000-0000-000000000722') is null then
   raise exception 'referenced duplicate was not chosen as stable anchor'; end if;
end $$;
set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000701',true);
select public.refresh_foreground_presence('00000000-0000-0000-0000-000000000711',1,1);
reset role;
do $$ begin
 if (select count(*) from public.encounters)<>2 then raise exception 'post-upgrade refresh created duplicate'; end if;
 if (select encounter_id from public.connection_requests where id='00000000-0000-0000-0000-000000000731')<>'00000000-0000-0000-0000-000000000722'::uuid then
   raise exception 'relationship reference changed'; end if;
 if (select overlap_end from public.encounters where id='00000000-0000-0000-0000-000000000722')<>now()-interval '10 seconds' then
   raise exception 'referenced stable anchor did not advance'; end if;
end $$;
rollback;
