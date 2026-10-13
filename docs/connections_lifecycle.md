# Production connection lifecycle

The lifecycle is `eligible encounter → pending request → accepted/declined`; only participants can read requests and connections. Production commands are authenticated RPCs and re-check the encounter's current availability and symmetric blocks. Clients cannot insert, update, or delete relationship rows directly.

Requests are idempotent. Repeating A→B returns the same pending request without another notification. If B sends while A→B is pending, the existing request is accepted and one canonical A-B connection is created. The accepted notification is addressed to the original sender. Connections use sorted user IDs, and a blocked pair is hidden and cannot accept, send, or remove through an unauthorized path. Unblocking does not recreate removed or invalidated relationships.

Request and acceptance notifications are created inside secured commands with conflict protection. Notification failure remains a separate concern from the underlying command boundary; push delivery is not part of this sprint.

Blocking permanently terminates active relationships and invalidates their pending
and accepted requests. Unblocking only removes the block restriction; it never
restores a connection or consent. A future eligible, mutually accepted request
creates a new connection ID and a separate conversation. Removal likewise ends
the original relationship. Local commands serialize by shared storage; server
commands and block triggers serialize by participant pair.

Migration `0025_permanent_relationship_termination.sql` archives connections using
`terminated_at` and requests using `invalidated_at`. Existing blocked pairs are
backfilled. Conversations and messages are retained under their original
connection IDs, and both RLS and chat RPCs require an active, unblocked connection.
Neither participant can retrieve historical messages after termination, even
after reconnecting. This migration does not define a retention interval or
perform retention deletion; those remain governed by applicable privacy and
data-retention policies. Apply the migration before deploying the client changes.

Run `psql -v ON_ERROR_STOP=1 -f supabase/tests/relationship_termination.sql` against
a disposable migrated database to verify consent, RLS, RPC denial, history
retention and reconnection isolation. The SQL test rolls back its fixtures.

To validate upgrades, run `supabase/tests/relationship_termination_backfill.sql`
on a disposable database containing migrations through `0024`; that test applies
`0025` inside a rolled-back transaction. To validate concurrent acceptance and
blocking, run `python3 supabase/tests/relationship_termination_concurrency.py
--host <socket-directory> --port <port> --database <disposable-database>` after
migration, with `--psql <binary>` if needed. It waits for real advisory-lock
contention and cleans up only its randomly identified fixtures.
