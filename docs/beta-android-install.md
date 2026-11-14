# Android staging candidate — 2026-11-05

**APK ready for local development installation. Auth URL settings were approved, applied and verified; controlled email/device testing remains pending.** No accounts were created or emails sent.

## Candidate and checks
- APK: `.artifacts/apks/mitzone-staging-0.1.0-debug.apk` (190,837,092 bytes), Android7/API24+, package `com.venkoi.mitzone`, version0.1.0+1, debug signed. Signature verified with Android Studio's bundled JDK. This is a development APK, not a signed release/distribution candidate.
- SHA256: `7df4e30c91ed9276a85a0075322b41a505e97a1b263f690526ff82ab5e2e2afb`.
- Ignored0600 `config/beta.json`: APP_ENV=staging, URL=https://arnikuoruzadqydhqfoj.supabase.co, existing client-safe sb_publishable key verified against staging Auth. No service_role, secret or management key in config. Key values are deliberately omitted here.
- Compiled Flutter kernel contains this exact URL/key and no original production project reference. No Firebase project resources or service configuration are packaged; Firebase push setup cannot initialize with this candidate. Plugin notification permissions still appear in the merged manifest; no push was enabled, deployed, requested on a device or tested.
- Build: `flutter build apk --debug --no-pub --dart-define-from-file=config/beta.json` succeeded. Build warnings concern future Java/Kotlin plugin compatibility, not build failure.
- Focused config/auth/recovery/navigation Flutter tests:85 passed. Preflight unit tests:5 passed.
- Preflight staging/network/no-background-location/release-signing-guard checks pass. Overall preflight remains BLOCKED by release signing, iOS team, live device/journey, operations and owner distribution gates. Its server-security gate is a manual evidence placeholder; staging migration/security verification was completed separately, not rerun by that script.
- ADB lists0attached phones. No APK was installed or launched.

## Auth inspection: staging-only GETs / config pull --dry-run
| Setting | Observed state | Assessment |
|---|---|---|
| Signup | Enabled | Ready |
| Email/password provider | Enabled | Ready |
| Email confirmation | Required | Preserve |
| Anonymous auth | Disabled | Preserve |
| Site URL | mitzone://auth/callback | Applied and read back |
| Redirect allowlist | mitzone://auth/callback; mitzone://auth/reset-password | Applied and read back |
| Custom SMTP | Disabled | Built-in mail restrictions apply |
| Email resend/recovery minimum interval | 1minute | Respect cooldown |

The Android compiled manifest handles browsable `mitzone://auth/...` links. The app owns AppLinks/PKCE callbacks; recovery uses exactly `mitzone://auth/reset-password`, and ordinary callbacks use the SDK without granting recovery authority. Existing tests include `mitzone://auth/callback?code=sign-up`. These source/test checks do not prove warm/cold physical-device callback behavior.

Signup supplies no emailRedirectTo, so it currently relies on the remote Site URL and email template. No app deep-link code change is required for the proposed URLs; live confirmation/template behavior remains unverified until authorized email tests.

### Approved remote URL changes — applied and verified
Only in Mitzone Staging arnikuoruzadqydhqfoj:
1. Set Site URL to `mitzone://auth/callback`.
2. Set exact allowed Redirect URLs to `mitzone://auth/callback` and `mitzone://auth/reset-password` (no wildcard).
3. Keep signup/email login enabled, confirmation required and anonymous sign-in disabled. Do not weaken confirmation to bypass mail delivery.

These were applied under explicit owner approval using a minimal file declaring only the two URL fields; all undeclared properties were preserved. See docs/beta-staging-auth-urls.md. No SMTP or other Auth changes were made.

With the built-in mailer, only existing Supabase organization-team addresses may receive Auth mail, and the project has a2-email/hour limit. Do not add testers to the organization just to bypass the restriction. Two confirmation messages can exhaust that hour; recovery must wait or use an approved existing SMTP service. Non-team beta addresses require approved custom SMTP (or a separately reviewed mail hook). No new paid service, SMTP change, hook or test email was authorized or created here.
Source: https://supabase.com/docs/guides/auth/auth-smtp and https://supabase.com/docs/guides/auth/testing-auth-flows.

## Two-phone installation
1. Use two consenting Android7+ test phones. Enable Developer options → USB debugging, connect by USB, unlock and approve this Mac's debugging prompt.
2. Run `/Users/josema/Library/Android/sdk/platform-tools/adb devices -l`; both must show `device`, not `unauthorized`.
3. For each serial, check `adb -s PHONE_SERIAL shell pm path com.venkoi.mitzone`. If it prints an installed package, STOP and identify that installation/signature/environment. Do not uninstall it, clear data, or overwrite a production installation. This candidate retains the existing application ID and label.
4. For a clean test phone, run (with the full adb path if adb is not on PATH):

```sh
adb -s PHONE_A install /private/tmp/mitzone-beta/.artifacts/apks/mitzone-staging-0.1.0-debug.apk
adb -s PHONE_B install /private/tmp/mitzone-beta/.artifacts/apks/mitzone-staging-0.1.0-debug.apk
```

No `-r`, downgrade or uninstall flags. Do not sign up or request recovery until account/email testing is authorized and Auth prerequisites are fixed. Installation/launch was not performed during this preparation.

## Authorized future two-account acceptance run
After approval to create staging test accounts/send email, and after Auth prerequisites:
1. Register A/B with controlled eligible addresses on their respective phones; confirm on the same phone/installation and complete separate profiles.
2. Request/recover a password on that same installation; retain PKCE storage (no reinstall/data clear), check valid and expired links, then sign in with the new password. Respect email limits.
3. Voluntarily enable foreground presence on both phones in the same real place; wait for actual shared-observation eligibility. No simulated location; verify no permission is mistaken for consent.
4. Encounter → request from A → acceptance by B → send/receive chat both ways. Request alone must not establish a connection.
5. Stop presence: collection ends and stays off after background/resume; existing accepted chat remains usable. Verify expiry and permission-denial states.
6. Block: both accounts lose relationship/chat access; stale actions fail. Unblock must not restore the old relationship/history. Submit a report; ordinary users cannot read reports.
7. Check network failure/retry, TalkBack,2x text and keyboard/scrolling. Record app build, phone OS versions and pass/fail without personal data or tokens. Use docs/beta-two-device-smoke.md for the full checklist.

Still deferred: push, Edge Function parity (including account deletion where exposed), release signing/distribution, report-review ownership and final beta operational/privacy gates. None was enabled or changed here.
