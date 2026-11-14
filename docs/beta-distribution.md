# Private beta distribution — current blockers and next actions

Reviewed 2026-11-04. This is preparation and local inspection, not authorization to sign with new credentials, upload, publish, deploy migrations or write production data. No new paid service is required by this plan.

## Android: shortest practical validation path

- The coordinator recorded a successful local Android debug compile. A debug APK built without runtime defines is compile evidence only: normal startup fails closed without valid backend configuration.
- `adb devices -l` currently lists no attached device. Connect an authorized Android test phone first; use two consenting accounts/devices for the shared-presence → encounter → mutual connection → bidirectional chat → block/report exercise. Simulated location is not real presence evidence.
- Select an owner-authorized nonproduction backend and an ignored local configuration based on `config/beta.example.json`: `APP_ENV=staging`, HTTPS `SUPABASE_URL`, and a client publishable/anon key only. Passing preflight validates configuration shape, not backend ownership, deployed migrations, grants or service health. Do not automatically reuse development/production configuration.
- `android/key.properties` is absent in both the beta worktree and original checkout. The new release guard deliberately refuses debug-key fallback. The owner must select an existing owner-controlled signing key, or separately approve key creation, and supply local signing metadata securely. Never print or commit key files/passwords. Keep the existing application ID `com.venkoi.mitzone` and verify signing compatibility with any installed copy before attempting an update.
- Once staging and signing are explicitly selected, build a local candidate and exercise registration, confirmation, profile persistence, recovery, presence/Stop/expiry, connections, chat and safety controls on actual devices. Uploads or sharing a build with testers require separate owner approval. Optional push must remain honestly unavailable until its configuration/delivery is verified; it is not a substitute for in-app refresh.

## Email confirmation and recovery are separate gates

The native Android manifest handles the `mitzone` scheme and `auth` host. Recovery explicitly requests `mitzone://auth/reset-password`; the selected staging Supabase project must allow that exact redirect and retain the verified recovery template/PKCE flow. Follow `docs/password-recovery.md` for warm/cold, expiry/replay and new-password-login checks.

`SupabaseAuthRepository.signUp()` currently passes **no `emailRedirectTo`**. Registration confirmation therefore follows the selected Supabase project's Site URL and email-template settings. Recovery allowlisting does not prove registration returns to the app. Inspect the intended staging Site URL/template and test the actual confirmation email on the same installation; record whether the app callback or browser-confirm-then-sign-in flow works. Do not silently change shared server settings, invent an unapproved redirect, disable confirmation or weaken auth to make the test pass.

## iOS: distinguish local compilation from TestFlight eligibility

Local inspection found macOS **14.8.9**, selected `/Applications/Xcode.app` **16.2**, and Apple Swift **6.0.3**. No alternative Xcode was found in `/Applications`, the user's Applications directory or Spotlight results, and no standard system/user `.xctoolchain` installation was found. No applications or OS settings were updated.

1. **Current dependency compilation blocker:** the resolved Firebase iOS SDK is **12.19.0**. Its package requires Swift tools **6.1**, while the installed compiler is 6.0.3. Generated Flutter SPM package metadata has been repaired; it does not resolve this compiler mismatch. Do not downgrade dependencies or alter package contracts merely to hide the host problem.
2. **Current TestFlight/upload requirement:** since April 28, 2026, iOS builds uploaded to App Store Connect must be built with **Xcode 26 or later using iOS 26 SDK or later**. Apple's upload documentation explicitly applies this build requirement to TestFlight as well as customer distribution. Xcode 16.3 might address the local Swift 6.1 minimum, but is insufficient for current TestFlight submission. [Apple SDK minimum requirements](https://developer.apple.com/news/upcoming-requirements/?id=04282026a), [Apple upload-build requirements](https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds).
3. **Host prerequisite:** Apple's requirements list Xcode 26 on macOS **15.6 or later**; even Xcode 16.3 requires macOS 15.2. The current macOS 14.8.9 host therefore needs an owner-approved OS/Xcode upgrade or an already available compatible Mac. Xcode 26 supports an iOS 15 deployment target, so using its SDK need not raise this app's existing iOS 15 minimum. [Apple Xcode system requirements](https://developer.apple.com/xcode/system-requirements/).

No Apple development team is configured in the checked-in Xcode project. After obtaining a compatible build host, the owner must select an authorized existing Apple team/provisioning setup, validate the candidate on a physical device, and explicitly approve any App Store Connect/TestFlight upload. This review does not assume account availability or authorize purchases.

## Evidence required before inviting users

Record the chosen staging project, candidate version/build and signing identity without credential values; migrated security-test/staging parity evidence; two-account real-device results; actual auth email delivery/callback behavior; report-review and feedback ownership; finalized privacy/contact/age/retention disclosures; and a rollback/support plan. Local compile/tests, existing documentation and configuration shape are not substitutes for these observed results. See `docs/beta-readiness.md` for the coordinator's final combined gate status.
