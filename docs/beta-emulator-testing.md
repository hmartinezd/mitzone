# Two-emulator staging test — 2026-11-05

## Running environments
Both independent emulators are running with the existing staging APK installed:

| Account slot | AVD | ADB serial |
|---|---|---|
| A (not created) | Mitzone_Staging_A | emulator-5554 |
| B (not created) | Mitzone_Staging_B | emulator-5556 |

AVD home: `/private/tmp/mitzone-staging-avds`. Each AVD has fresh independent userdata and a distinct Android identity (identifier values not retained). Existing Medium_Phone_API_37.0 and existing worktree changes were preserved. These temporary AVDs are local test environments, not durable backups.

Host: Apple Silicon,16GB RAM,8 logical cores, Hypervisor.Framework available, about91GiB initially free. Installed SDK: platform/build tools36/37; emulator37.2.12, platform-tools37.0.1; one installed Google Play ARM64 API37image. No additional SDK components were required/downloaded.

API37forces software GLES and increases each guest to4096MB despite the requested1536MB. Both boot and render, but startup is slow and memory compression is high. A initially appeared offline; a targeted ADB reconnect recovered it without a reset. Do not equate this with smooth performance on physical phones. If concurrent use becomes unresponsive, stop only one of these test AVDs and preserve its data, or review a lower-resource ARM64 system image before downloading anything.

## Actually verified
- APK installed successfully on BOTH new AVDs. Installed base.apk SHA256 matches the existing candidate `7df4e30c91ed9276a85a0075322b41a505e97a1b263f690526ff82ab5e2e2afb`.
- Both render the approved teal/sage sign-in screen; screenshots are under `.artifacts/emulator-staging/`.
- Read-only VM metadata inspection of each live initialized Supabase client confirms REST URL `https://arnikuoruzadqydhqfoj.supabase.co/rest/v1`; both auth sessions are null. No keys/tokens were printed or retained. The debug APK has no production project ref/Firebase project config. This verifies runtime backend selection, not a successful authenticated API request.
- Fresh Android identities/data stores are distinct; each can hold its own future account/session.
- GPS console accepted clearly illustrative ocean coordinates longitude-30/latitude0 on each. Neither app enabled presence or acquired app location permission during this check. Console acceptance is not proof of app location consumption or real-world attendance.
- An ERROR-ONLY `mitzone://auth/reset-password?error=access_denied&error_code=otp_expired` intent opens “Recovery link expired” on BOTH apps. No auth code/token was supplied, no email requested, and no session was granted. Both were returned through Back to Sign In afterward.
-92existing local fixture-based tests passed: encounter/presence, connections, chat, blocking and event presence overlap. Command: `flutter test --no-pub test/features/encounters test/features/connections test/features/chat test/features/blocking test/features/events/presence_overlap_test.dart --reporter compact`. Log `/private/tmp/mitzone-emulator-regression.log`.
- No accounts created, emails sent, presence records activated, connection/chat/report test records submitted, production changed, push enabled, or functions deployed.

The first UI assertion looked only at text and missed Flutter content descriptions; corrected it to inspect accessibility labels and reran successfully. Runtime expression evaluation was unavailable in this standalone debug APK (no compilation service), so the endpoint/session checks read existing VM fields instead. Neither diagnostic issue required app/backend changes.

Evidence: runtime-verification.json, safe-smoke-results.json, isolation-verification.json and screenshots in `.artifacts/emulator-staging/`. Historical SQL/security checks remain documented separately; they were not repeated or passed off as live two-user tests.

## Controlled two-account run — pending authorization
No account/email action below may run until the owner explicitly approves creating the two staging accounts and sending the required Auth emails. Use distinct controlled email addresses; never paste passwords, confirmation URLs, PKCE verifiers or tokens into chat/screenshots/logs.

Built-in SMTP remains limited to EXISTING Supabase organization-team addresses and2messages/hour across the project. Do not add testers as organization members to bypass this. Two confirmations may use the hour; recovery needs a later window. For other addresses, obtain separate approval/configuration for an existing SMTP service first. Auth URLs and required confirmation are already configured and independently verified.

| Step | Execute after approval | Pass criterion / limitation |
|---|---|---|
| Signup | Create A in emulator5554 and B in5556 using the normal UI | Distinct accounts; confirmation required; no direct DB/admin insertion |
| Confirmation | Human opens each email in webmail/browser INSIDE the corresponding emulator | Same-installation PKCE exchange succeeds; no cross-emulator link sharing |
| Login/profiles | Enter credentials manually in each app; create minimum clearly labeled test profiles | Separate sessions/profiles persist; no access to another owner's private profile |
| Presence permission | Deny once, then grant while-in-use and separately opt in | Permission alone never activates presence; denied/unavailable states remain honest |
| GPS fixtures | Use commands below for controlled synthetic positions | Clearly labeled synthetic staging observations; never claim genuine physical attendance |
| Encounter | Keep both apps foreground through actual server eligibility duration; use ordinary client calls only | No fabricated/forced encounter rows, shortened clocks, admin acceptance or security bypass |
| Request/accept | A requests from its observed fixture encounter; B explicitly accepts | Request alone gives no connection/chat; acceptance creates mutual access |
| Chat | Send small labeled test messages in both directions; exercise refresh/network retry | Both see canonical messages; retry does not duplicate; no push assumed |
| Stop | Stop A, background/resume, then repeat for B | Collection stops; old lease cannot be revived; accepted chat remains usable |
| Block/report | Block in one app; try stale views/actions from both; unblock; submit labeled report | Symmetric restrictions; unblock does not restore old consent/history; reports not readable by ordinary users |
| Recovery | After rate-limit window, request on one emulator and open email in that SAME emulator | Real PKCE recovery, new-password login, invalid/replayed links fail; no reinstall/data clear between request and link |

Illustrative GPS commands (LOCAL emulator only):

```sh
/Users/josema/Library/Android/sdk/platform-tools/adb -s emulator-5554 emu geo fix -30 0
/Users/josema/Library/Android/sdk/platform-tools/adb -s emulator-5556 emu geo fix -30 0
```

These coordinates are synthetic test fixtures, not real presence evidence. The current foreground location adapter does not carry an origin/isMocked flag into its domain observation. Therefore emulator results can exercise consent/lease/matching protocol behavior with explicit fixture labeling; they cannot certify location authenticity, real physical overlap, background behavior/OEM lifecycle or genuine real-world encounters. Do not alter this safeguard boundary or claim real attendance merely to make an emulator test pass. Real-device presence validation remains a separate beta gate.

After approval, automate only the UI/protocol steps that do not expose secrets; human interaction remains necessary for selecting/approving eligible addresses, entering passwords and reading real confirmation/recovery email. Emulator location/notification permissions should be exercised through their normal dialogs, not pre-granted to bypass consent.

## Next owner action
Confirm two controlled, eligible EXISTING organization-team email addresses and explicitly authorize two staging account registrations and their confirmation emails. Keep recovery approval within the same controlled test scope but schedule it after the email limit resets. Until then, both installed apps remain signed out and ready at Sign In.
