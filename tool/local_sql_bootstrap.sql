-- Disposable PostgreSQL harness only, not a hosted Supabase/auth deployment.
create role anon nologin;
create role authenticated nologin;
create role service_role nologin bypassrls;
create schema auth;
create table auth.users(id uuid primary key);
create function auth.uid() returns uuid language sql stable as $$
  select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid
$$;
grant usage on schema auth, public to anon, authenticated, service_role;
grant execute on function auth.uid() to anon, authenticated, service_role;
-- psql variable supplied by the runner; standalone bootstrap defaults to the
-- legacy platform model for reproducibility of the historical test baseline.
\if :{?strict_grants}
\else
  \set strict_grants false
\endif
\if :strict_grants
  alter default privileges in schema public revoke all on tables from anon, authenticated, service_role;
  alter default privileges in schema public revoke all on sequences from anon, authenticated, service_role;
  -- Actual staging catalog: disabled exposure removes CRUD, but leaves Dxtm.
  -- TRUNCATE is dangerous despite RLS; application migration0031 removes it.
  alter default privileges in schema public grant truncate, references, trigger, maintain
    on tables to anon, authenticated, service_role;
  -- Model automatic RLS enablement independently from Data API table exposure.
  create function public.local_test_enable_new_table_rls() returns event_trigger
  language plpgsql security definer set search_path=pg_catalog as $$
  declare created record;
  begin
    for created in select * from pg_event_trigger_ddl_commands()
      where object_type='table' and schema_name='public'
    loop
      execute format('alter table %s enable row level security',created.objid::regclass);
    end loop;
  end $$;
  revoke all on function public.local_test_enable_new_table_rls() from public;
  create event trigger local_test_auto_rls on ddl_command_end
    when tag in ('CREATE TABLE','CREATE TABLE AS','SELECT INTO')
    execute function public.local_test_enable_new_table_rls();
\else
  -- Legacy platform defaults assumed by the historical migrations. Explicit
  -- application revokes/grants still apply and RLS remains enabled by source.
  alter default privileges in schema public grant all on tables to anon, authenticated, service_role;
  alter default privileges in schema public grant all on sequences to anon, authenticated, service_role;
\endif
