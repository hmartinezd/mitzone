# nearby-events deployment review — pending approval

Prepared 2026-10-14. No deployment, remote configuration change or secret
rotation has been performed. Deploy only this function; do not deploy all
functions, push database migrations/configuration, or prune remote functions.

## Comparison and artifact

The owner confirmed that deployed code has the old silent 502 branch and lacks
`providerStatus`, `Ticketmaster request failed`, and `formatProviderDate`.
Those signatures match repository revision `7f828ac`. This is a historical
comparison, not a byte-for-byte comparison with a downloaded deployment:
the actual deployed source has not been supplied/downloaded here.

The intended candidate is the existing repository implementation introduced
in `992813b`, unchanged by this work:
`supabase/functions/nearby-events/index.ts`.
SHA-256: `1e406735373338061a420acc51b567492d7f809ff9e3faab5bb97a5ab5e0114f`.

Changes relative to the historical implementation:

- Trim the existing provider key and return sanitized 503 if absent/blank.
- Format the two UTC query dates to whole seconds, retaining the 14-day window.
- Retain HTTP 502 and its error message for non-success provider responses,
  adding numeric `providerStatus` and logging only the upstream status.

Success remains `{events: [...]}` with the same normalized fields and credits.
Invalid/missing bearer credentials or an unvalidated user remain 401 before
provider access; invalid coordinates remain 400. Network, JSON and schema
exceptions retain sanitized 500 responses. An empty provider result remains
200 with `events: []`. No fabricated records are supplied.

Authentication still calls `auth.getUser()` using the incoming Authorization
header and the anonymous server key, not a service-role key. There are no
database writes, presence/check-in calls, new permissions, background tracking
or coordinate/token logging. The existing foreground coordinates are sent
only to Ticketmaster for this query, as before. CORS preflight stays public.

## Local validation

Deno 2.5.6 was downloaded to `/tmp/mitzone-deno-runtime`, without installing
global tools. Run with any equivalent local Deno installation:

```sh
deno check supabase/functions/nearby-events/index.ts
deno test --no-config --import-map=supabase/tests/nearby-events/import_map.json supabase/tests/nearby-events/index_test.ts
flutter test test/features/events/event_repository_test.dart --reporter expanded
```

Results: type check passes against the real public Supabase SDK declarations;
one Deno test with 20 passing steps, zero failures; three Flutter client tests
pass. The Deno test executes the actual entrypoint with an import-map auth mock,
intercepted `Deno.serve`, environment reads and fetch. It has no network or
environment permissions and cannot reach real services. It covers preflight,
authentication gating/header forwarding, coordinate validation, missing key,
date/bounds/query contracts, 400/401/403/429/500/503 upstream failures, safe
diagnostics, normalized imagery/attribution, malformed payloads and network
failure. Mocks live under `supabase/tests`, outside the deployment entrypoint.

This is not a local Supabase gateway integration test: CLI/Docker are not
installed here. It does not validate real JWTs, key validity, provider quota,
email/session infrastructure, or live photo availability. Earlier Phase 1
Flutter validation on the same Dart code passed analysis and all 460 tests.

## Pre-deployment gates and backup

The project host in `config/dev.json` identifies project
`bqlerixwfusmfesfhupz`. Confirm this target with the owner before execution.
Use an installed, authenticated Supabase CLI; never paste access tokens into
commands, logs or this document.

Record the deployed function version, source, and gateway `verify_jwt` setting
from the Dashboard. The deployment command below assumes `verify_jwt = true`,
the repository default. If the deployed value differs, stop and review how to
retain that value before approval; do not silently change gateway settings.
The handler's own user validation must remain in either case.

Before deployment, download the **actual deployed source** into a separate
backup directory, not over the candidate in this workspace:

```sh
mitzone_backup_dir="$(mktemp -d /tmp/mitzone-nearby-events-backup.XXXXXX)"
mkdir -p "$mitzone_backup_dir/supabase"
cp supabase/config.toml "$mitzone_backup_dir/supabase/config.toml"
supabase --workdir "$mitzone_backup_dir" functions download nearby-events --project-ref bqlerixwfusmfesfhupz --use-api
diff -u "$mitzone_backup_dir/supabase/functions/nearby-events/index.ts" supabase/functions/nearby-events/index.ts
```

`diff` exits 1 when differences are found; review those differences before
continuing. Keep the backup directory path and actual gateway setting with
the release notes. Preserve the backup beyond temporary-directory cleanup.
The copied config retains repository settings; ensure it reflects the recorded
gateway setting before using it for rollback. Never use an assumed Git revision
as a substitute for the actual deployed backup.

## Proposed deployment command — DO NOT execute before approval

From `/Users/josema/Projects/mitzone`, after backup, source comparison and
confirmation of the gateway setting:

```sh
supabase functions deploy nearby-events --project-ref bqlerixwfusmfesfhupz --use-api
```

This targets only `nearby-events`, using existing remote secrets. No
`--no-verify-jwt`, `--prune`, secret-setting or database commands are included.
The CLI's API bundler avoids requiring local Docker.
[Official CLI reference](https://supabase.com/docs/reference/cli/supabase-functions-deploy).

Expected impact: subsequent invocations use corrected date formatting and
actionable provider diagnostics. Home/Events may recover if the old request
format caused rejection. A rejected key/quota/provider outage can still return
502, now with its upstream status. Missing provider configuration becomes 503.
No app release or data migration is needed. The Flutter client already handles
502/503 and ignores the additive diagnostic field.

The import remains the existing floating `supabase-js@2`; this check resolved
SDK 2.117.3. Deployment bundling may resolve a different version later. There
is no new dependency change in this candidate. No new fetch timeout or schema
hardening has been bundled into this focused synchronization.

After approval/deployment, verify unauthenticated access is rejected and make
one authenticated discovery request for approved Tampa coordinates, without a
presence/check-in action. Check the execution's status and sanitized
`providerStatus` if it fails. Confirm success retains event fields and credits,
and review Home photographs from real events. Do not log provider request URLs,
headers, keys, tokens, exact coordinates or raw provider error bodies.

## Rollback — only if needed after deployment

If authentication, response contracts or availability regress, redeploy the
captured source with its recorded gateway setting:

```sh
supabase --workdir "$mitzone_backup_dir" functions deploy nearby-events --project-ref bqlerixwfusmfesfhupz --use-api
```

Repeat the unauthenticated/authenticated checks. This replaces function code;
no database rollback or secret rotation is required. The old silent 502 may
return. A source redeploy is not guaranteed to reproduce an old bundled SDK
because the original import floats; preserve any available original bundle
or Dashboard version artifact with the backup for that reason.
