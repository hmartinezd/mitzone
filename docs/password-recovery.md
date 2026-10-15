# Password recovery

Status (2026-10-14): the project owner confirmed the Android email-to-app
recovery flow is working after adding the mobile redirect to Supabase's
allowlist. Automated validation passed: 442 tests, including 60 authentication
and route-policy tests; Flutter analysis reported no issues. Android warm/cold
expired-link dispatch was also checked with token-free callbacks.

The owner's confirmation is a manual validation result, not an automated live
service test. Live iOS recovery, separate warm/cold valid-link runs, expired or
replayed email checks, and a separately recorded new-password login still need
the platform release checklist below. Local iOS runtime validation is blocked
by the existing Xcode/Firebase SDK toolchain mismatch. A successful `/recover`
response alone does not prove email delivery or redirect configuration.

## Flow and security boundaries

- Sign in → Forgot password? opens a separate recovery request form. The
  acknowledgement is the same for existing and unknown accounts. Raw Supabase
  errors are never shown. Concurrent requests are disabled; a repository-wide
  one-minute cooldown also prevents accidental repeat requests from replacing
  the pending PKCE verifier.
- Supabase `resetPasswordForEmail` sends the email. Supabase controls the email
  token's expiry and one-time verification. The client never retrieves an
  existing password or constructs its own recovery token.
- The redirect is exactly `mitzone://auth/reset-password`. The installed
  Supabase SDK stores its PKCE verifier and the recovery purpose locally. Only
  a successful server code exchange with that recovery purpose, a matching
  current session, and an unexpired JWT unlocks the new-password form and
  repository mutation. A `type=recovery` URL or an ordinary authenticated
  session cannot authorize this operation. Implicit token fragments are rejected.
- Open the email on the same device/app installation where it was requested.
  A later request replaces the earlier verifier: use the latest email. Do not
  clear app data or reinstall between requesting and opening it. The PKCE code
  is single-use and expires five minutes after issuance; the email token has
  its separately configured expiry. See [Supabase PKCE documentation](https://supabase.com/docs/guides/auth/sessions/pkce-flow).
- Recovery state is observed before normal authenticated navigation. Checking,
  invalid, expired, ready, and completed recovery states stay outside protected
  app routes. Sign-out, expiry, or session replacement revokes the in-memory
  password-update grant. It is not reconstructed from an ordinary persisted
  session. If the reset form cannot be resumed after an app restart, request a
  fresh link; no URL parameters can restore that grant by themselves.
- Password policy is enforced by Supabase. Confirmation mismatch is rejected
  locally, and weak/same-password errors allow correction without exposing
  provider details. A completed update consumes the grant. Back to Sign In
  ends the local recovery session before normal login. Cancel also signs out.
- Android and iOS retain the existing `mitzone` scheme. Flutter's built-in deep
  link router is disabled so app_links and the repository process callbacks
  once, including cold starts. PKCE prevents another app claiming the scheme
  from exchanging a captured code without this installation's verifier.
- No service-role key, SMTP secret, token, or password belongs in source,
  application configuration, logs, screenshots, or test reports. SDK fixtures
  use mocked HTTP and in-memory PKCE storage, with no live Firebase or network.

## Required Supabase Dashboard setup (project owner)

Use the project selected by the ignored `config/dev.json` for development, and
repeat for the release environment's project. These are server settings; a
Flutter build does not apply them.

1. Open **Authentication → URL Configuration**
   (`https://supabase.com/dashboard/project/<project-ref>/auth/url-configuration`).
   Under **Redirect URLs**, add exactly `mitzone://auth/reset-password` and save.
   Retain the approved Site URL and other existing registration/OAuth redirects.
   Do not add wildcard redirects or put recovery codes in the allowlist.
2. Open **Authentication → Sign In / Providers → Email**. Keep Email enabled and
   the existing signup/confirmation behavior. Check **Email OTP Expiration**:
   it must be finite; the usual default is 3600 seconds. Record the project's
   approved value in the release validation record. Recovery verification and
   session expiry are enforced by Supabase, not by a client-generated timestamp.
   Retain the approved password requirements and session/JWT policy.
3. Open **Authentication → Email Templates → Reset Password**. The reset action
   must link to `{{ .ConfirmationURL }}` so Supabase verifies the email token
   before redirecting to the app. A minimal valid body is:

   ```html
   <h2>Reset your Mitzone password</h2>
   <p><a href="{{ .ConfirmationURL }}">Reset password</a></p>
   <p>If you did not request this, ignore this email.</p>
   ```

   Do not replace the action with a direct `{{ .RedirectTo }}` link: that would
   bypass the email-token verification step.
4. Open **Authentication → Email → SMTP Settings** and configure a production
   SMTP provider: approved sender name/address, host, port, username and password.
   Store the SMTP credential only in Supabase. Verify the sending domain with
   the provider's SPF/DKIM/DMARC instructions and disable email link rewriting
   or click tracking for authentication emails. Keep credentials out of Flutter.
   Supabase's default sender is for testing, restricts recipients to project
   team addresses, and has low limits; it is not a production delivery service.
   See [Supabase SMTP setup](https://supabase.com/docs/guides/auth/auth-smtp).
5. Open **Authentication → Rate Limits**. Verify the existing email send limits
   suit expected recovery traffic; retain server abuse protections. The client
   cooldown supplements those controls and is not a security rate limit.
6. Confirm the test inbox belongs to a consenting project test user. Check Auth
   logs and the SMTP provider delivery log if a request is accepted but no
   message arrives. Do not disable email confirmation or weaken authentication
   to work around delivery failures.

Reference: [redirect URLs](https://supabase.com/docs/guides/auth/redirect-urls),
[email templates](https://supabase.com/docs/guides/auth/auth-email-templates),
[Flutter deep-link handler configuration](https://docs.flutter.dev/ui/navigation/deep-linking).

## Required real-device/emulator validation before completion

Record Android and iOS separately; automated/mocked exchanges do not satisfy
this checklist.

1. Run Mitzone with the intended Supabase project. From Sign in, request a link
   for a controlled registered test inbox. Confirm the neutral acknowledgement
   and actual email delivery. Do not create a user or send to an unrelated inbox.
2. With Mitzone running, open the latest email link on that same device. Confirm
   the app opens, shows checking, then Set a new password. Choose and confirm a
   new password privately. Verify Password updated and Back to Sign In; sign in
   using the new password and verify the previous password no longer works.
3. Request another link after the send interval, stop the app (without clearing
   its data), and open the latest email. Verify cold-start validation reaches
   the reset form. Complete or cancel it, then verify ordinary login/logout.
4. Reopen a consumed link and verify it cannot update a password. Check an
   expired email and a malformed callback: neither may expose the form. A new
   request must remain available. Verify normal sign-in/registration still work.
5. Record platform/build, delivery result, configured email expiry, warm/cold
   results, replay/expiry results, and new-password login. Never record live
   links, passwords, access/refresh tokens, or verifier contents.

Token-free native dispatch smoke checks (these test routing/error states only):

```bash
adb shell 'am start -W -a android.intent.action.VIEW -d "mitzone://auth/reset-password?error=access_denied&error_code=otp_expired" -p com.venkoi.mitzone'
xcrun simctl openurl booted \
  'mitzone://auth/reset-password?error=access_denied&error_code=otp_expired'
```

Do these before requesting a live email, or after finishing it: cancelling
recovery signs out and removes the pending verifier, invalidating a pending link.

## Automated validation

```bash
flutter analyze
flutter test test/core/auth/password_recovery_repository_test.dart \
  test/core/auth/auth_repository_test.dart test/features/auth \
  test/app/router/auth_route_guard_test.dart --reporter expanded
flutter test
```
