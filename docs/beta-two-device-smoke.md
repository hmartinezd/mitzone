# Real-device beta acceptance — still outstanding

Use only an owner-selected nonproduction Supabase project, dedicated adult test
accounts and consenting testers. Do not use simulated coordinates as evidence
of physical overlap. Do not log credentials, exact coordinates, report details,
tokens or private message bodies. A SQL fixture pass does not satisfy this sheet.

Prerequisites: approved staging migration/function parity, same-install
registration email confirmation and recovery configuration, owner-controlled
signing, at least two physical Android phones, and a named report reviewer.
No staging deployment or distribution is authorized merely by this checklist.

| Step | Pass criterion |
|---|---|
| Register A/B | Both can sign up, receive confirmation, return to the intended app/login, create separate minimum profiles; existing email/password rules stay enforced |
| Recover A | `mitzone://auth/reset-password` returns on the same installation, validates recovery session, accepts a changed password and restores ordinary sign-in; expired links fail safely |
| Profile boundary | A can edit A; B sees only permitted public fields after eligible context; another account cannot read/write private A fields |
| Permission vs consent | Discovery permission alone never records presence; cancelling consent creates no evidence; each account has its own consent |
| Voluntary overlap | A/B physically share coarse context, explicitly activate and keep Home foreground/visible long enough for at least5min genuine overlap; background/hidden views stop observations |
| Encounter | A/B see one stable shared-context encounter per session segment; no exact pin, raw cell identifier or duplicate card/count after refresh |
| Mutual connection | A sends once; B sees the request on entering/reselecting Matches; only B can accept; no chat before acceptance; seven-day cutoff is enforced |
| Chat | Both send and receive without reopening; failures preserve drafts/retry identity; duplicate taps do not duplicate messages |
| Stop | Stop removes active evidence; pending/failure remains truthful; no refresh revives the stopped UUID; a new session requires explicit activation |
| Block | B blocks A; both lose request/profile/chat/history access as applicable; direct stale links and sends fail; unblock does not restore old consent/history |
| Report | A can submit an appropriate report once; failed submission is not shown as success; authorized reviewer can actually triage it; ordinary users cannot read reports |
| Device failures | Denied permission, disabled services, stale GPS, lost connectivity, background/foreground, account switch and restart remain recoverable and truthful |
| Release review | Actual candidate version/backend, permissions, policy/contact/age/retention/deletion disclosures and reviewer ownership are recorded before invitations |

Registration confirmation currently depends on the selected Supabase Site URL/
email template because signup does not pass emailRedirectTo. Recovery allowlist
verification alone is insufficient. Current runtime configuration/signing and
physical devices have not been supplied/selected by this local test batch.
