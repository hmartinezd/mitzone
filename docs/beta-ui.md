# Beta UI integration — Kinetic Teal & Muted Sage

Date: 2026-11-04. Implemented only in `/private/tmp/mitzone-beta`; no commits, pushes, publication, deployments or production writes. The original working checkout is untouched.

## Completed bounded batch

- Added the owner-approved light visual foundation: mint-white canvas, cyan primary containers, muted teal, amber accents, Space Grotesk headings and Plus Jakarta Sans body text. The screen-export roles govern the implementation: canvas `#F3FBF9`, ink `#151D1C`, primary `#006A65`, cyan container `#31EADF`, secondary `#2F6763`, mint `#B2EAE4`.
- Added local font assets; no runtime font fetch or paid dependency. Official SIL Open Font License notices are packaged and registered with Flutter's license registry.
- Switched `MitzoneApp` to the light theme without changing auth, bootstrap, routing, repositories or services. Retained the legacy dark theme for compatibility and tests.
- Replaced Home's hard-coded navy hero with the approved static overlapping-experiences metaphor. No person dots, tracking map, verification badge, fabricated attendee counts, or sample provider records were added. Informational hero art is excluded from screen-reader traversal; its accompanying text retains normal text scaling.
- Added an honest low-activity card only when all four social sources have loaded with no activity. It leads to the existing Events route. Existing real discovery, foreground presence, incoming requests, connections, chat summary and profile feedback remain reachable.
- Converted discovery cards to the approved white/photo/title hierarchy while retaining carousel scrolling, real provider image URLs, loading/broken/missing-photo states, category/context/date/distance, Google Maps credit, image attribution, test/demo badge and existing event-only tap authorization. Places remain informational. Changed the mixed-carousel link to **See events** to describe its actual destination.
- Applied the shared rounded surfaces, fields, chips, buttons and typography to existing Events browsing. Event Detail now shows the actual supplied HTTPS event photograph first, or an explicit photo-unavailable fallback, preserving provider credits/source access, join/leave intent and all loading/error/retry states. No presence activation was added to event details.
- Retained all five functional branches, their labels, selected index, state preservation, back/deep-link behavior and GoRouter contracts. The bottom bar receives the approved light/mint appearance and grows for large text; the four-tab Stitch proposal was not substituted for working navigation.
- Removed hard-coded dark text/surface assumptions in shared page, empty-state, card and confirmation presentation. Destructive confirmations now use `onError` text; primary loading indicators follow the actual button foreground. The existing destructive-style merge precedence is retained and regression-tested.
- Added a transparent Material surface above the page's painted background so ListTile ink and interactions retain a valid visible Material ancestor. This fixes the real profile-settings assertions introduced by the solid light canvas.
- Fixed a beta-critical encounter presentation gate: a valid server-derived `cell:*` encounter no longer disappears because it has no event-catalog entry. It shows **A shared area** and a coarse-overlap explanation without exposing the raw cell token or inventing a venue. Actual event titles remain when available, and missing historical context has an honest fallback.
- Matches send/accept/decline commands are awaited, lock duplicate/conflicting submissions while pending, and restore retryable controls with safe error feedback on repository failure. They do not optimistically invent relationship state or bypass server authorization. Request controls wrap at narrow widths.
- Entering Home/Matches/Chat now invalidates only existing authorized social read providers, including when entering through programmatic branch changes; reselecting an active social tab also refreshes it. GoRouter's five branches, `goBranch` calls, reselect-to-root and back/state semantics remain intact. This does not invalidate discovery/location, activate presence, send messages or invoke mutation controllers. The configured encounter repository path was inspected and uses a table read for this refresh.

## Visual source and deliberate functional mapping

Source exports and native reference remain in `/private/tmp/mitzone_stitch_preview/reference/` and that preview's `lib/`. They are the latest saved screen IDs:

| Screen | Saved Stitch screen |
| --- | --- |
| Home | `efa8b844467b4df192a9bb60e34e2802` |
| Discovery | `161791a42d3e41ba8ebee2eb4cbb3a87` |
| Event Detail | `7b7265227026498d99f0b0dc77d333e4` |

Design system: `5adc436cda8347fe8a9d50169acf149a`, **Kinetic Teal & Muted Sage**, version 2. Project: https://stitch.withgoogle.com/projects/1169891625207640647.

This is a functional beta translation, not a claim of pixel-identical completion of all destinations. Production UI uses real authorized data and existing flows instead of the preview's illustrative events, portraits, private-bookmark terminology, fixed timers or unsupported venue/verification claims. Existing carousel behavior is preserved. Cyan action labels use dark teal for readable contrast rather than the white-on-cyan source treatment. New Groups, Follow/Join Zone, maps, paid features and four-tab reorganization remain deferred.

## Validation evidence

- **137 passing tests** in the focused Home, Events/detail/loading, app, complete router, shared-widget and theme batch. Command: `flutter test --no-pub test/features/home/presentation/home_screen_test.dart test/features/events/event_experience_test.dart test/features/events/events_loading_state_test.dart test/app/app_test.dart test/app/router test/shared/widgets test/app/theme --reporter expanded`. Log: `/private/tmp/beta-ui-final-test.log`.
- Additional **9 passing action/theme tests**, including the new destructive-role regression and required 4.5:1 text/action contrast pairs. Log: `/private/tmp/beta-ui-actions-test.log`. These overlap the larger batch and must not be added as unique test counts.
- **14 passing app/license/action tests** after adding packaged font notices: `/private/tmp/beta-ui-license-actions-test.log`.
- **19 passing profile-navigation/Matches tests** after correcting the Material boundary: `/private/tmp/beta-ui-final-safety-test.log`.
- **24 passing navigation/Matches tests** after the final read-only refresh change: `/private/tmp/beta-ui-refresh-test.log`. This includes a fetch-counter regression proving incoming requests are reread on returning to Matches and on reselect, three failing-repository command tests using the real connection controller, and three coarse/historical/event-context presentation tests. These batches overlap; the coordinator's final whole-suite run supplies the unique final total.
- Home tests now exercise the actual approved light theme, include 320×480, 414×896, landscape and tablet at 1×/2× text, and preserve credit, photo fallback, informational-place, event navigation and social-state checks. Event navigation tests scroll the real card into view before tapping at narrow widths.
- Static analysis reached Dart source successfully and reported no findings in this UI owner's files. At the recorded pass it still had chat/presence informational findings owned by concurrent workers; their final global check supersedes this snapshot.
- Local tooling issue repaired without changing native project configuration: `flutter pub get` initially could not copy SPM plugin sources because `build/ios/SourcePackages` was absent. Preparing that ignored directory and running one coordinated `flutter pub get` succeeded and generated `ios/Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage/Package.swift`. Workers should use `--no-pub` while sharing this worktree.

## Still unverified / beta acceptance gates

No configured Mitzone runtime, emulator or backend was launched by this UI workstream. The earlier isolated preview's screenshots do not validate this integrated app. The coordinator must record final platform builds and capture the integrated Home → Events → Detail flow against these saved references in an explicitly authorized nonproduction environment, using real provider records or clearly labeled test fixtures. Verify narrow/2× text interaction, VoiceOver/TalkBack, keyboard, focus, source attribution and safety controls on the actual build. Full responsive and motion fidelity outside this bounded batch remains unreviewed.

The original discovery/auth/social/backend contracts are retained; repository source and widget tests do not prove provider health, deployed grants, real location behavior, successful reporting, moderation operations, chat delivery or private-beta distribution readiness.

Coordinator build evidence identifies an additional iOS blocker: resolved Firebase SDK 12.19 requires Swift tools 6.1, while the installed Xcode 16.2 uses Swift 6.0.3. Generated SPM metadata is now present; dependency downgrade or native-project workaround was not performed. An owner-approved local Xcode/toolchain upgrade is required before iOS build acceptance. The coordinator separately recorded an Android debug compile; that is not a signed/distributed beta or device acceptance.
