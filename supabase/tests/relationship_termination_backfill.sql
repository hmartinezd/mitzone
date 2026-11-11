-- Run on a disposable database with migrations through 0024 (before 0025).
-- Verifies migration of a previously hidden connection; all changes roll back.
begin;
insert into auth.users(id) values ('00000000-0000-0000-0000-000000000101'),('00000000-0000-0000-0000-000000000102');
insert into encounters(id,user_a,user_b,context_id,overlap_start,overlap_end)
values ('00000000-0000-0000-0000-000000000110','00000000-0000-0000-0000-000000000101','00000000-0000-0000-0000-000000000102','test:legacy-presence',now(),now()+interval '30 minutes');
insert into connection_requests(id,sender_user_id,recipient_user_id,encounter_id,status)
values ('00000000-0000-0000-0000-000000000111','00000000-0000-0000-0000-000000000101','00000000-0000-0000-0000-000000000102','00000000-0000-0000-0000-000000000110','accepted');
insert into connections(id,user_a_id,user_b_id,encounter_id)
values ('00000000-0000-0000-0000-000000000112','00000000-0000-0000-0000-000000000101','00000000-0000-0000-0000-000000000102','00000000-0000-0000-0000-000000000110');
insert into conversations(id,connection_id,user_a_id,user_b_id)
values ('00000000-0000-0000-0000-000000000113','00000000-0000-0000-0000-000000000112','00000000-0000-0000-0000-000000000101','00000000-0000-0000-0000-000000000102');
insert into messages(conversation_id,sender_user_id,body,client_message_id)
values ('00000000-0000-0000-0000-000000000113','00000000-0000-0000-0000-000000000101','retained legacy history','legacy-message');
insert into blocks(blocker_user_id,blocked_user_id)
values ('00000000-0000-0000-0000-000000000101','00000000-0000-0000-0000-000000000102');
\ir ../migrations/0025_permanent_relationship_termination.sql
set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000101',true);
delete from blocks where blocker_user_id=auth.uid();
do $$ begin
  if exists(select 1 from connections) or exists(select 1 from conversations)
    or exists(select 1 from messages) or exists(select 1 from connection_requests)
    then raise exception 'backfill restored historical access'; end if;
end; $$;
reset role;
do $$ begin
  if (select count(*) from conversations)<>1 or (select count(*) from messages)<>1
    or (select count(*) from connections where terminated_at is not null)<>1
    or (select count(*) from connection_requests where invalidated_at is not null)<>1
    then raise exception 'backfill did not retain and invalidate history'; end if;
end; $$;
rollback;
