# Presence and chat safety — local evidence

2026-11-04. Changes are isolated and not deployed. No configured app/service was launched.

Presence now uses account-scoped consent/expiry memory; the old device-wide
consent flag is deliberately not migrated. Restoring local expiry never starts
location collection or proves server activity. Stop remains reachable with
unknown local status, displays pending/failure/retry, and only clears active
presentation after server confirmation. Starting again remains available.

An explicit activation refreshes at60s intervals only while Home is visible and
the application is resumed, for the original maximum30min lease. Hidden/background
views pause refresh. Restored/paused sessions require explicit Resume; after app
restart the in-memory lease may be unavailable, in which case the UI instructs
Stop followed by a new explicit activation. This is intentionally not app-wide
passive/background collection. Stale (>30s) or future (>5s) platform observations
fail closed. Account/lifecycle authorization is rechecked after location resolves.

Stop invalidates pending observations and waits for an already-submitted write
before sending secured Stop. The distinct server refresh UUID boundary also
prevents a late refresh reviving a removed/expired/new session. A local service
or fixture test does not prove actual database execution or device behavior.

Focused presence run: **17 passing tests** in foreground_presence_test.dart and
foreground_presence_safety_test.dart, including account isolation, pending and
failed Stop, delayed observations, restored unknown state, bounded refresh,
hidden/background pauses and prevention of duplicate writes. Log:
`.artifacts/beta/presence-tests.log`. Exact-lease HTTP mock regression is separate.
That HTTP mock regression passes as well: activation stores the server UUID,
refresh submits that UUID to the distinct refresh RPC, and confirmed Stop clears
it so a later refresh cannot fall back to activation. No network service is used.

Chat focused run: **12 passing tests** covering existing local authorization,
draft-safe failures, stable retry identities, new identity after edits,
foreground receipt, background pause and hiding revoked conversation content.
Log: `.artifacts/beta/chat-tests.log`. Read-only refresh is10s while the conversation
is visible/resumed; it reauthorizes through existing repositories and does not
introduce a new backend or paid service.

SQL execution including repeated-refresh canonicalization, upgrade preservation,
two-account domain flow and actual contention now passes; see beta-backend.md.
Outstanding: physical location/OS lifecycle testing, account-switch/sign-out server state,
two-account delivery, actual report submission/reviewer operations, retention/
deletion verification and manual screen-reader/device acceptance. These remain
release gates rather than implied passes.
