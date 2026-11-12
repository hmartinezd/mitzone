# Private beta readiness — implementation batch 1

Date: 2026-11-04. Worktree: `/private/tmp/mitzone-beta`, detached from base
`8b57d5f`. The owner's main checkout is unchanged. Local code changes are not
deployed migrations, a signed distribution candidate, or evidence of live service health.

## Parallel ownership

| Workstream | Owner | Scope |
|---|---|---|
| Flutter | beta_ui | Approved Stitch v2 tokens/fonts/theme, existing Home/discovery/event presentation, navigation appearance and coarse encounter display |
| Backend | beta_backend | Additive report/presence/encounter authorization migrations, seven-day actionability and disposable SQL regressions |
| Safety/QA | beta_safety | Account-scoped consent, observable Stop failures, bounded foreground refresh and presence regressions |
| Coordination/distribution/chat | coordinator | Local distribution checks/signing guard, platform builds, chat refresh/failure recovery, final combined verification |

Only owners edit their assigned files. Flutter package setup is serialized;
tests/builds use `--no-pub` afterwards. No new service or paid dependency is required.

## Concrete changes in this batch

- Integrate the approved Kinetic Teal & Muted Sage appearance using the frozen
  saved Stitch exports and isolated native preview. Retain five working router
  branches and live data. Sample people/events/photos, verification promises and
  the concept four-tab behavior are not copied into production data paths.
- Repair account-scoped presence consent and Stop feedback. Raw observation
  remains foreground/explicit only, resolved server-side to coarse context.
- Restore report insertion privileges without granting users report reads or
  arbitrary moderation/identity updates; remove direct client presence writes.
- Correct server/client actionability to the owner's **seven days after the
  last shared observation**. This does not authorize seven days of location
  collection, extend message retention, bypass blocks or remove mutual consent.
- Add chat send guards, draft-preserving failure/retry with stable command IDs,
  ten-second foreground refresh via existing authorized repositories, and
  background/hidden-view suppression. Remote block/removal rechecks close access.
- Add Android release INTERNET permission (previously debug/profile only),
  remove silent debug-key release signing, ignore local signing credentials,
  and correct iOS location-purpose text to include discovery separately from presence.
- Add read-only `tool/beta_preflight.py` with credential-safe tests; it never
  connects to a service or prints configuration/key values.

## Release gate — explicit pass/fail criteria

Unchecked or unavailable evidence counts as **not passed**, not an assumed pass.

| Gate | Pass criteria | Current evidence/status |
|---|---|---|
| Core Dart regression | Full test suite and analysis pass on the combined final worktree; relevant additions cover genuine failure/authorization cases | PASS locally: 484 Flutter tests, no analysis issues; five Python preflight tests pass |
| Android compile | Debug compile succeeds; owner-signed candidate also starts with intended staging configuration | Final combined debug APK compiled; signed/configured candidate not yet built |
| iOS compile | Simulator build succeeds with pinned dependencies; signed build validates on a physical device | BLOCKED: installed macOS14.8.9/Xcode16.2 cannot compile current Firebase dependencies; current TestFlight uploads require Xcode26+ on compatible macOS |
| Registration/recovery | Two authorized accounts can register, confirm email, sign in/out, recover access and return through correct auth deep links | Repository/local regression evidence only; staging email/deep-link/device exercise outstanding |
| Profiles | Minimum profile persists across restart; optional fields stay optional; peer public-profile access respects current relationship/block rules | Local regression coverage; cross-device profile/avatar verification outstanding (remote avatar storage is not assumed) |
| Presence | Explicit consent per account; discovery never enables presence; permission denial/error is truthful; only foreground refresh while active; Stop success/failure, expiry, account changes and resume are tested | PASS locally: consent/Stop/foreground regressions and SQL lease tests; physical location and staging parity outstanding |
| Encounters/connections | Two physical devices create valid bounded overlap; genuine past encounter remains actionable ≤7days, fails after7days; request/accept/decline and stale requests enforce blocks | PASS locally: seven-day boundary, stable identity, concurrent dedup and mutual-consent SQL tests; live two-device journey outstanding |
| Chat | Connected users receive messages without reopening; duplicate submit/retry is safe; drafts survive failure; background refresh stops; removed/blocked conversations deny reads/sends | 12 focused local chat tests pass; two-account staging delivery outstanding |
| Reporting/blocking | Reports persist under authenticated insert-only authority; reviewer can triage through authorized operations; both sides lose interaction access on block; unblock does not resurrect history | PASS locally: report ACLs and symmetric block SQL journey; operational reviewer and real submission still outstanding |
| Data/security | Disposable migrated SQL tests prove grants/RLS/RPC ownership/expiry/blocking, including primary flow; approved staging schema matches candidate | PASS on disposable PostgreSQL: nine SQL/concurrency/upgrade suites; no hosted schema parity verified or deployment authorized |
| Privacy/operations | Owner approves entity/contact, minimum age, retention/deletion scope, actual Google/Ticketmaster/Supabase/Firebase disclosures and report-review/feedback ownership | BLOCKED on owner/legal/operations details and verified deletion behavior |
| Device/accessibility | Candidate tested on intended device platforms, keyboard/compact/2× text, screen readers, contrast, permission/lifecycle failures | Widget coverage available; manual device/screen-reader verification outstanding |
| Distribution | Owner-controlled signing, correct backend/environment, reproducible versioned candidate, tester list/instructions, feedback/incident owner, explicit upload approval | BLOCKED: no release signing/staging selection/publication approval. No build uploaded. |

## Distribution preparation

Run `python3 tool/beta_preflight.py` for read-only local gates. Optionally pass
`--config /path/to/authorized-staging.json`; this validates shape without
contacting the backend or echoing secrets. The normal result is BLOCKED until
manual/live gates have evidence. The tool does not certify readiness or auto-approve release.

Android release tasks intentionally stop if `android/key.properties` is absent.
Use `android/key.properties.example` locally once the owner selects an existing
upload key; never commit key files/passwords. Debug builds still work. A compiled
debug APK with no runtime defines is compile evidence and will fail closed at
startup; it is not a usable beta release candidate.

For iOS, provide macOS15.6+ with Xcode26+ (or an existing compatible Mac), then an
authorized Apple team/provisioning setup. Do not downgrade backend/client
dependencies just to mask the current host toolchain mismatch.

Once a candidate passes the gates, prepare the platform's existing private
distribution channel (e.g. internal Android testing/TestFlight if the owner
already has the relevant account), named invited testers, short test script,
feedback contact and rollback plan. No account purchase, paid service, signing
credential creation, upload or publication is authorized by this document.

## Deliberately deferred

Groups, premium/monetization, QR scanning, passive/background presence, new
recommendations, attachments and online/typing indicators. Existing working
features are preserved rather than rebuilt. Push is best-effort and cannot
replace in-app notifications/chat refresh or be claimed delivered without device evidence.

The inherited encounter-processing duplicate/caller-dependent context blocker
is fixed in0030 and verified with repeated, opposite-caller, concurrent and
legacy-upgrade regressions. See `beta-backend.md` for the local platform model
and its limits. Formatting/brace cleanup is mechanical; CI formatting scopes
owned `lib`/`test` sources instead of generated third-party iOS package copies.

## Final local evidence for this batch

- Full combined Flutter run: **484 passed**, `.artifacts/beta/flutter-test-final.log`.
- `flutter analyze --no-pub`: **no issues**, `.artifacts/beta/analyze-final.log`.
- Python preflight regressions: **5 passed**.
- Final Android debug compile: **passed**, `.artifacts/beta/android-build-final.log`.
- Release signing guard: **expected rejection confirmed** using local Gradle
  dry-run with no signing properties; no release artifact was created/published.
- Presence focused service/widget regressions: **17 passed**; an additional
  mocked HTTP test proves the repository uses the exact-lease refresh RPC and
  clears its lease after Stop. These overlap the full Flutter total.
- Database checks: **nine suites/checks pass** on fresh local PostgreSQL, including
  canonical deduplication, real lock contention, two-account domain journey and
  legacy upgrades. Hosted auth/email/staging/physical-device checks remain open.
- iOS simulator compile: **blocked by local Swift toolchain/dependency mismatch**.
- No configured application was launched, no production data changed, and no
  commits, pushes, deployments or publication occurred.

Current iOS distribution requirements and primary Apple sources are recorded in
[beta-distribution.md](beta-distribution.md). The real-device acceptance script is
[beta-two-device-smoke.md](beta-two-device-smoke.md). No local fixture substitutes
for registration email, physical presence or the installed two-phone journey.
