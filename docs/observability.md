# Analytics and crash reporting

Mitzone uses FlutterFire Firebase Analytics and Firebase Crashlytics. The
integration is best-effort: a provider outage or unavailable local Firebase
configuration never affects the product journey. Debug builds disable
Crashlytics collection; release/beta builds enable it.

Tracked events are: `app_opened`, `authentication_completed`, `profile_updated`,
`foreground_presence_started`, `foreground_presence_stopped`,
`discovery_viewed`, `profile_viewed`, `connection_request_sent`,
`connection_request_accepted`, `connection_request_declined`,
`conversation_opened`, `message_sent`, and `notification_opened`.

Event names are stable lowercase snake_case. Events contain no precise or
historical location, tokens, credentials, email/phone, names, message/report
contents, or other unnecessary profile data. Analytics is measurement only,
never application state.

## Runtime validation

Firebase Android/iOS app configuration (`google-services.json` and
`GoogleService-Info.plist`) and Firebase Console Analytics/Crashlytics setup
remain manual beta activation steps. Run a release/profile build on a real
configured device, verify events in Analytics DebugView as appropriate, and
use a deliberate test crash to verify Crashlytics. Do not commit Firebase
credentials/configuration files or secrets. Code complete and runtime/manual
activation pending are intentionally separate.
