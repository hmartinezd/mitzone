# Staging verification — 2026-11-05

## Remote evidence
- Authenticated account can access exact project Mitzone Staging, arnikuoruzadqydhqfoj; ACTIVE_HEALTHY, us-east-1, PostgreSQL17.11.
- Read-only SQL runs as supabase_read_only_user with transaction_read_only=on.
- No public application tables, no public policies, and no supabase_migrations.schema_migrations table exist. Thus none of0001–0030 is recorded as applied.
- Official CLI3.0.0 staging-only db push --dry-run --skip-vault completed with exit0 and listed exactly0001–0030. Seeds/functions/custom roles were not included.
- Owner explicitly authorized the CLI temporary staging database login role solely for this connection/dry-run. It is the only authorized remote mutation in this task; no app migrations/data changes were made. Temporary-role expiry/cleanup is managed by Supabase; not independently verified here.
- Post-dry-run read-only query reconfirmed zero public app tables and no migration-history table; see remote-verification.json.
- ensure_rls event trigger is enabled (O); public.rls_auto_enable enables RLS on new public tables and adds no access policies.
- postgres public table defaults exclude SELECT/INSERT/UPDATE/DELETE, confirming disabled automatic CRUD exposure. They nevertheless retain TRUNCATE/REFERENCES/TRIGGER/MAINTAIN for anon/authenticated/service_role.
- anon/authenticated/service_role have public schema USAGE but no CREATE.
- postgres public function default ACL has only postgres EXECUTE; no global default ACL overrides were listed. Migrations explicitly restrict secured RPCs and internal helpers. supabase_admin creator defaults differ, so apply via the normal postgres migration role, not supabase_admin.
- CLI labels the hosted main branch as production. Every remote target was the staging ref above; the original Mitzone project was not queried or changed beyond appearing in the account project listing.
- API exposed-schema setting could not be established from database-session settings (null); this does not imply Data API disabled. Verify public schema reachability in the post-migration staging API smoke test.

## Local preparation and tests
- Original deployment bundle remains exactly0001–0030 with all SHA-256 hashes matching source; original project links and existing beta changes preserved. No staging project link file was created; commands use the explicit target ref and isolated CLI home/workdir.
- New local migration: /private/tmp/mitzone-beta/supabase/migrations/0031_explicit_staging_privileges.sql. Deliberately NOT copied into the0001–0030 deployment bundle yet.
-0031 resets anon/authenticated table ACLs on all13app tables, restores explicit app operations and column restrictions, and removes dangerous residual privileges from service_role. It does not change RLS policies, disable automatic RLS, enable automatic exposure, grant direct message reads, or permit direct presence writes. Push receives no new service-role CRUD grants.
- Six SQL suites plus two concurrency tests passed with all0001–0031 migrations under BOTH legacy grants and the actual staging model (no CRUD defaults, residual Dxtm, automatic RLS):16 passes total.
- Passing suites: reporting/presence authorization,7day refresh, stable-session dedup, two-account SQL journey, relationship termination, explicit privileges; concurrency: acceptance/block serialization and opposite-caller encounter dedup.
- New privilege regression verifies owner operations, cross-user restrictions, token conflict denial, column-limited notification updates, secured chat RPCs, direct-message/presence-write denial, anonymous denial, internal lock-helper ACLs, and denied TRUNCATE on all app tables.
- Updated two existing fixtures to expect42501 for direct message table reads; secured RPC and retained-history assertions remain, including fresh-conversation isolation.
- Negative control through0030 fails as expected: anonymous TRUNCATE on profiles remains. This proves the regression catches the pre-fix security concern.
- Test logs: /private/tmp/mitzone-sql-vjynd47r (strict), /private/tmp/mitzone-sql-atrueu4p (legacy), /private/tmp/mitzone-sql-dui8pnv3 (negative control). All clusters stopped, Unix sockets only, TCP disabled. Initial sandbox shared-memory failures were resolved by authorized local execution outside sandbox.
- Local PostgreSQL17.6 is a compatible major-version fixture harness, not full hosted GoTrue/PostgREST/physical-device verification on17.11.

## Exact next remote changes requiring owner approval
1. After approval, copy the tested0031 into this isolated staging migration bundle, verify hashes and rerun staging-only dry-run for all31migrations before applying.
2. Apply0001–0031 ONLY to arnikuoruzadqydhqfoj. This creates the13app tables, associated indexes/constraints/triggers/functions/RLS policies, and Supabase migration bookkeeping, then installs explicit restricted ACLs. No fixture users/data, seeds, Edge functions, auth configuration changes, exposure toggles, or app deployment are part of this authorization request.
3. Perform read-only post-apply checks of effective grants, table owners, RLS and policies. Stop on any discrepancy before device testing.

Do not approve applying0001–0030 alone: it lacks required CRUD grants and leaves residual dangerous privileges.0031 removes those privileges from the current app tables; future tables still require an explicit privilege migration because platform defaults are unchanged.

## Remaining beta gates
- Remote migrations await explicit approval;0031 has only been tested locally and is not part of the completed30-migration remote dry-run.
- Actual email/auth, staging API behavior and two-real-account device journey remain unverified.
- Push remains deferred: dispatch-push queries nonexistent blocks.id and ignores that lookup error. No push functions were deployed; fix/test its fail-closed block checks before enabling push.
- Existing Android signing/distribution and iOS/Xcode gates remain outside this database task.

0031 SHA-256: 6a819f2b81cb3dd5bd3c13ad2e3aed41258ede1f9eda338a53b831dac8d56615
