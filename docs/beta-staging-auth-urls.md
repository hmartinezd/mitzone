# Staging Auth URL update — 2026-11-05

Applied only to **Mitzone Staging / arnikuoruzadqydhqfoj**, after explicit owner authorization.

- Site URL: `mitzone://auth/callback`.
- Exact redirect allowlist: `mitzone://auth/callback`, `mitzone://auth/reset-password`.
- Email confirmation remains required.

## Before changing settings
Verified the exact staging project name/ref and ACTIVE_HEALTHY status. Reviewed Android source/compiled APK intent filters and AppLinks/PKCE routing for both URLs. The ordinary callback test proves registration callbacks do not grant recovery authority. Recovery tests cover stored verifier, genuine recovery purpose, invalid/expired links, session restrictions and reset navigation. **47 focused tests passed.** No handler change or APK rebuild was required. Physical warm/cold link behavior remains unverified.

## Remote change and read-back
Used a separate minimal local configuration at `/private/tmp/mitzone-staging-auth-urls-only/supabase/config.toml` declaring only `auth.site_url` and `auth.additional_redirect_urls`. Pre-apply diff had exactly2declared updates. The official CLI applied exactly these2properties;9undeclared properties were preserved, no secrets sent, API/DB/storage unchanged. The hosted main-branch label production referred to this dedicated staging project, not the original Mitzone project.

An independent read-only config pull --dry-run against the staging ref read back the exact URLs above and `auth.email.enable_confirmations=true`. Evidence: `.artifacts/staging-auth-diff-sanitized.json` (no credentials). Existing original project links remain unchanged.

No production modifications, SMTP changes, accounts, emails, push, Edge Functions, commits or build publication occurred. The direct credential-lookup attempt was cancelled before it retrieved a credential or made a remote request; the update used the authenticated official CLI.

## Readiness and next action
Auth URL configuration is ready for **controlled** testing. End-to-end delivery and physical callbacks have not been exercised. Custom SMTP remains disabled; built-in email only accepts existing Supabase organization-team addresses, with2emails/hour across the project. Two confirmations can exhaust that hour; schedule recovery later. Do not grant testers organization membership to bypass this restriction. Non-team tester addresses need separately approved SMTP configuration.

**Next:** connect two Android test phones by USB, enable USB debugging and approve this Mac. Select two controlled eligible email addresses and explicitly authorize staging account creation/email tests before registration or recovery. Do not create accounts or send emails yet.

Install the existing staging debug APK only onto clean/identified test installations; its package ID is shared with the original app, so do not overwrite an existing production installation. See docs/beta-android-install.md and docs/beta-two-device-smoke.md. The APK is ready for local installation, not release distribution; release signing and operational gates remain separate.
