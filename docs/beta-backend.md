# Backend batch — verified on disposable local PostgreSQL

2026-11-04. No migrations were deployed and no production/staging data was changed.

- 0026 grants authenticated report submission columns only, preserving RLS and
  preventing ordinary users from reading or assigning moderation status.
- 0027 removes direct authenticated presence INSERT/UPDATE/DELETE, retaining
  owner reads and secured RPCs. Encounter evidence foreign keys use SET NULL so
  Stop can revoke evidence already referenced by a derived encounter.
- 0028 implements the owner's seven-day actionability window from the last
  shared observation, rejects future/expired observations, checks symmetric
  blocking through a definer boundary, and updates public-profile/request/
  compatibility authorization. Client eligibility uses the same strict cutoff.
- 0029 separates explicit activation from refresh. Refresh carries an exact
  server evidence UUID, retains the original expiry and cannot recreate stopped,
  expired or replaced leases. A gap over90s or movement resets overlap start.
  Server timestamps are captured after the per-owner transaction lock.
- The Flutter repository caches the activation lease for the authenticated
  account, uses the distinct refresh RPC, and clears that lease after confirmed
  Stop. Its mocked HTTP regression verifies no refresh can silently invoke activation.

PostgreSQL17.6 was built from official source under `/private/tmp/mitzone-pg17`.
`tool/run_local_sql_tests.py` creates a fresh700-permission cluster directory,
uses a private Unix socket with TCP disabled, ignores external PG environment
settings, applies migrations, runs rollback-only SQL tests and stops the server.
It never discovers or connects to a hosted project. No system-wide install occurred.

## Duplicate encounters fixed in0030

`0030_stable_session_encounters.sql` replaces the refresh-timestamp uniqueness
tuple with canonical evidence UUIDs plus each observed segment start. Refresh
updates overlap end monotonically while preserving encounter identity; opposite
neighboring-cell callers converge on the same context. A gap/movement starts a
new segment. Existing historical rows are retained, with one referenced current
anchor preferred so request/connection foreign keys are not rewritten/deleted.
The processing function's returned rows also enforce seven-day/symmetric-block
authorization rather than bypassing RLS through SECURITY DEFINER.

## Executed evidence

- Five full-migration SQL suites pass: report/presence ACLs; seven-day window/
  lease refresh; stable-session deduplication; two-account journey; permanent
  relationship termination.
- Two real contention checks pass: acceptance versus blocking, and simultaneous
  opposite-cell processing waiting on the same unique key and yielding one row.
- Two separate upgrade suites pass: pre0025 termination backfill, and pre0030
  legacy-duplicate anchoring without deleting IDs or changing request references.
- The relationship fixtures were corrected to use past observation ends under
  the approved seven-day rule instead of inventing future attendance.

Evidence: `.artifacts/beta/sql-final.json`, `sql-dedup-upgrade.json` and
`sql-relationship-upgrade.json`, with complete per-command logs under the
reported `/private/tmp/mitzone-sql-*` directories. All servers were stopped.

## Limits and remaining beta gates

The bootstrap deliberately models historical Supabase platform grants and
supplies a minimal auth.users/auth.uid identity boundary. Real PostgreSQL grants,
RLS, RPCs, constraints, triggers and concurrency were exercised, but this is not
a running Supabase GoTrue/email service. Elapsed presence in SQL fixtures is
explicitly seeded by the test administrator, not physical-location proof.

Perform a real two-account/two-device journey on an explicitly selected staging
environment after separate deployment authorization. Effective grants, actual
delivery, moderation triage, retention and deployed schema parity remain unverified.
