# Mitzone recovery validation — 2026-11-11

The permanent workspace is coherent for a **reviewed local recovery checkpoint**. It is not yet a release-ready private beta. No commits were created during recovery validation; the owner subsequently authorized an independent local recovery checkpoint.

## Restored and verified

- File manifest: **464 fully recovered/restored, 0 partial, 2 historical paths still missing**. “Restored” includes documented authorized reacquisition/reconstruction, not an assertion of lost byte identity.
- Nine licensed font binaries and both official SIL OFL notices restored. Space Grotesk400/500/600/700 came from the four exact v22 URLs preserved in session evidence. Plus Jakarta Sans400/500/600/700/800 came from Google Fonts URLs with SHA256/size verified against cached google_fonts6.3.3 metadata. Font tables validate all nine declared weights. Original lost-file hashes were unavailable; original binary equality is not claimed. Provenance: `.recovery/font-provenance.json`.
- All existing pubspec font/asset paths resolve. **pubspec.yaml did not need editing**; dependency lockfile unchanged.
- `config/beta.json` reconstructed mode0600 using authenticated read-only access to **Mitzone Staging arnikuoruzadqydhqfoj**, its HTTPS URL and client-safe publishable key. Auth health returned200. No secret/service-role key embedded. Config is ignored; private `.recovery/` now also ignored.
- Database0026–0031 and recovered location/navigation/Kinetic/presence/chat sources preserved from the preceding verified recovery. No application or backend source changed during this validation phase.
- The CLI refreshed its local version-cache file `supabase/.temp/cli-latest`; project links and remote resources were not changed. All nonsecret manifest checksums verified after recording this metadata refresh.
- Two test-only repairs: stale Events tab journey now uses Explore → Search all activities, preserving participation/absence-of-presence assertions; navigation-test conditional received required braces.

## Actual validation

- Asset-enabled complete Flutter suite: **511 PASS**. First run:510PASS,1FAIL due to stale removed Events tab expectation; corrected and rerun.
- Final asset-enabled navigation/event/location/presence-safety/chat/blocking batch with final historical Space Grotesk assets: **86 PASS**.
- `flutter analyze --no-pub`: **No issues found**.
- Python beta-preflight unit tests: **5 PASS**.
- Beta preflight: **NOT READY**,4PASS/7BLOCKED. Local staging shape, Android Internet permission, no background-location permission and no debug-release-signing fallback pass. Release signing, Apple team, two-account live journey, server-runtime parity check, moderation/privacy operations, device/accessibility evidence and owner release approval remain gates. Automated manual gates are not evidence that historical staging migrations failed.
- `flutter build apk --debug --no-pub --dart-define-from-file=config/beta.json`: **PASS**. Output `build/app/outputs/flutter-apk/app-debug.apk`; hash recorded privately in `.recovery/apk-verification.json`. APK packaging independently matches all11current font/license files. Dart kernel contains only the verified staging runtime URL/client key, and no production project ref. This is a new debug APK, not the lost historical artifact.
- Build emits nonfatal Firebase-plugin Kotlin Gradle compatibility and Java deprecation warnings; no upgrade attempted during recovery.
- Fresh permanent isolated emulator created under `.recovery/avds/`, keyboard enabled. APK installed/launched successfully; actual onboarding and then signed-out login screen rendered in the teal/sage direction. Captures: `.artifacts/recovery-validation/`. No Firebase google_app_id resource present; push remains unconfigured. No credentials entered, accounts created, confirmation/recovery emails sent, or presence enabled.
- Authenticated bottom navigation, real GPS-to-discovery, Stop/block/report and two-user messaging are **not runtime-verified**. Automated tests cover navigation/location/safety contracts using explicit test fixtures, not live-service success. No auth bypass was used.
- SQL sources remain hash-verified from recovery; database runtime tests not rerun and no remote database writes performed.

## Unresolved gaps

- The original `.artifacts/apks/mitzone-staging-0.1.0-debug.apk` and original `.artifacts/emulator-staging/` evidence remain missing. New outputs do not restore their history.
- Original Plus Jakarta/font license byte identity cannot be certified; authorized official replacements of the approved font families are documented, not arbitrary substitutions.
- Historical staging probes returned404for nearby-discovery and nearby-events. This session did not deploy functions or prove current Google Places/Ticketmaster results. Treat live discovery as unresolved.
- Need an existing authorized staging login for protected-screen/emulator testing; physical presence cannot be established with simulated GPS.
- No local release signing or Apple provisioning restored. Debug emulator installation works; publication is not authorized.

## Preservation and checkpoint

All writes for this phase are inside this permanent workspace. Original repository, damaged temporary worktree and existing private backup were not altered. During recovery validation, no commit, push, backend deployment, production write or build publication occurred. Read-only staging metadata/key/health access only.

Safest next step: review this report/manifest, then authorize a **new independent local Git repository here**, based on the recorded baseline provenance, without attaching to or repairing the original Git/worktree metadata. Before staging anything, verify ignores for `config/beta.json`, `.recovery/`, `.artifacts/`, build outputs, signing/Firebase files; inspect the exact staged diff and run a secret scan. Create a local recovery checkpoint only after that review, with no remote configured or push. Keep the existing backup untouched and add an owner-approved second private backup of the validated workspace (including ignored local configuration separately) before further beta work.

## Local checkpoint safety review

The owner authorized a local-only recovery checkpoint after validation. The independent repository has no remotes, shared object store or original-worktree linkage.453reviewed source/assets/license/test/documentation files are included. Exact staged blobs were scanned; matches were reviewed as explicit test fixtures, XML keys or source identifiers, with no live credentials found. The actual staging publishable key is absent from staged blobs. Runtime config, Supabase link/cache metadata, private recovery evidence, build outputs and signing material remain ignored. Author identity is configured only in this repository. The resulting commit identity and clean-tree verification are recorded in the private local checkpoint receipt under `.recovery/`; no push or publication is authorized.
