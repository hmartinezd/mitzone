# Staging deployment result — 2026-11-05

## Authorized deployment completed
Target verified immediately before execution: **Mitzone Staging**, **arnikuoruzadqydhqfoj**, ACTIVE_HEALTHY, PostgreSQL17.11.

The tested0031 hash matched the prior review report. Added it to the isolated deployment bundle; all31versions and hashes match source. The final dry-run exited0 and listed exactly0001–0031 with no seed, roles file, Edge Functions, or vault changes. The approved staging-only push then applied all31 migrations and exited0.

CLI3.0.0 command:
```sh
SUPABASE_HOME=/private/tmp/mitzone-staging-cli-home /private/tmp/mitzone-supabase-cli-v3/supabase db push --remote=arnikuoruzadqydhqfoj --skip-vault --workdir /private/tmp/mitzone-staging-deploy-arnikuoruzadqydhqfoj --yes --output json
```
The CLI used the authorized temporary login-role path. Its display label “production” denotes the hosted project's main branch; the exact target was the staging ref, never the original Mitzone project.

## Post-deployment verification
- **31/31** migration-history versions and names match the manifest.
- **13/13** application tables owned by postgres have RLS enabled.
- Automatic RLS event trigger ensure_rls remains enabled.
- **18** RLS policies target authenticated only; owner predicates, eligible participant predicates and symmetric-block helper boundaries match the reviewed source.
- anon has no app-table privileges; anon/authenticated/service_role have no TRUNCATE/REFERENCES/TRIGGER/MAINTAIN on these13tables.
- authenticated cannot directly read/write messages or write raw presence evidence. Secured chat/presence RPCs retain authenticated EXECUTE.
- Application RPCs deny anon EXECUTE; lock_relationship_pair denies authenticated EXECUTE. The platform rls_auto_enable event-trigger function retains its existing ACL; no platform function/settings were changed.
- Catalog has_column_privilege checks confirm the exact restricted INSERT/UPDATE columns for reports, notifications, blocks, personality_profiles and device_tokens. Report inserts exclude server timestamps; notifications permit read_at updates only.
- **15/15 read-only HTTP checks pass:** Auth health200; Data API root401with explicit service-role-only metadata restriction; all13 app-table GETs deny anonymous access with401/SQLSTATE42501. Only a public client key was held in memory; no credentials were printed or saved.
- Authenticated PostgREST operations, email/auth callbacks and real-device journeys were NOT tested: this scope authorized schema deployment, not creation of test accounts or app-data fixtures.

## Failure handling
No migration failed. The first API probe incorrectly expected root metadata200 and reported401. Read-only investigation confirmed the endpoint intentionally requires service_role. Corrected the local probe expectation and reran successfully; no remote configuration changes or service-key escalation were used.

## Evidence
- bundle-manifest.json:31migration SHA-256 hashes.
- post-deployment-verification.json: migration history, table owners/RLS, policies, effective table/function grants (metadata only).
- column-privilege-verification.json: exact effective column privileges.
- api-read-only-results.json and api-root-response.json: credential-free GET results.
- Previous local regression evidence:16 SQL/concurrency passes across strict staging and legacy grant models; negative control without0031 detected residual anonymous TRUNCATE. Not rerun against hosted staging because those fixtures create users and application data.

Both original local production project-ref files and all existing worktree changes were preserved; no staging link file was created. No production database was targeted, no seeds or real-user data imported, no Edge Functions deployed, no auth/settings/push configuration changed, no commits/pushes/build publication occurred.

## Remaining two-device beta gates
1. Configure a local Android runtime file for this staging URL and public client key, verify APP_ENV=staging, and select an owner-authorized test build/install approach. Do not silently replace a production installation with the same application ID. No app build was changed/launched here.
2. Verify staging confirmation/recovery email delivery, permitted tester addresses and exact recovery redirect mitzone://auth/reset-password. Signup uses the Site URL/template because it supplies no emailRedirectTo. Auth-setting changes and new staging test-account creation require separate authorization.
3. Connect two physical Android devices and run the two-account smoke checklist: registration/profiles, voluntary foreground presence, genuine shared observation, encounter, request/acceptance, two-way chat, Stop, symmetric block and report. Simulated location does not establish actual presence.
4. Assign a report reviewer and complete beta privacy/support gates before inviting testers. Reports are stored safely, but moderator access is not an ordinary-client capability.
5. Optional push stays deferred: dispatch-push's nonexistent blocks.id/error handling must be fixed/tested before enabling it. Account-deletion/other Edge Function parity remains outside this authorized migration-only deployment and needs separate review/approval before exposing those actions.
6. Release signing/distribution still needs owner signing selection/approval; local device testing can use an explicitly selected development build. iOS retains the previously documented Xcode/macOS/toolchain/provisioning blocker; it was not re-audited or changed here.

Most useful next action: configure the Android staging candidate and run the authorized two-account journey on two real devices after the auth/email prerequisites are confirmed.
