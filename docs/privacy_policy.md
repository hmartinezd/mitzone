# Mitzone MVP Privacy Policy

Mitzone uses Supabase for email authentication, profiles, and configured
backend records. It uses Firebase Analytics and Crashlytics for aggregate
usage and crash diagnostics, and Firebase Cloud Messaging for notifications.
Nearby discovery sends location-based requests through the backend to Google
Places and Ticketmaster. Location permission for discovery does not activate
presence or make a person discoverable to others.
It does not sell personal data. The MVP may store authentication email,
optional profile fields, foreground presence/discovery context, connections,
requests, conversations/messages, reports, blocks, device tokens, and limited
diagnostic data to provide those features and keep them safe.

Presence is explicit and foreground-only. While “I’m here” is active, current
coordinates are sent to the trusted backend to resolve coarse place context and bounded time data to find
nearby shared activity. There is no background tracking, raw location history,
or exact-location display to other users. Users can deny permission or stop
presence. Analytics excludes precise location, contents, credentials, tokens,
contact details, and unnecessary profile PII.

Users can manage notifications, presence, blocks and reports, and can delete
their account in Settings. Auth deletion cascades the current user-owned
profile, presence, relationships, conversations/messages, notifications and
device-token records; local demo data remains on-device until app data is
cleared. Current storage does not yet define a complete retention schedule.
The final entity, contact, age threshold, rights process, jurisdiction and
production URL require legal/owner review. Material updates will be posted in
an updated policy and communicated in-app or through release communication.
