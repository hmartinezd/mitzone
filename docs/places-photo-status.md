# Optional Places photos: implementation and verification

Status (2026-11-18): implementation covered by automated tests; live photos remain
unverified. Do not describe this as a resolved upstream photo issue.

`nearby-discovery` requests `places.photos` and resolves at most one fresh photo
per valid place (at most 10 per search). Missing photo metadata makes no media
request. A failed, unsafe or timed-out photo preserves the place and its existing
UI fallback. Media resolution can add Google billable requests when photos exist
and up to four seconds to search latency. No persistent photo-reference cache is
introduced. API keys stay in server-side request headers; clients receive only
validated HTTPS Google image URLs and author display attribution.

The Flutter parser accepts the optional image fields. Existing discovery cards
show Google Maps source credit, author attribution and loading/error fallback.
Location refresh tests verify Google Places and Ticketmaster share refreshed
device coordinates without enabling presence.

## Live DEV evidence

Google returned HTTP 200 but no photo metadata for nearby Valrico/Tampa places
and an Eiffel Tower control. On the same Eiffel Tower place ID, both Details
field-mask header and `fields` query yielded only `id`; Text Search returned the
same ID without photos. This isolates the observed omission before application
normalization, but does not establish why Google omitted the data. Billing,
permissions and provider incidents are not confirmed causes.

Temporary diagnostics were removed from DEV. No production deployment was made.
The DEV deployment uses a bundled equivalent of the shared helper because it was
published through the dashboard editor; repository sources retain shared imports.

Further investigation is paused. A live successful provider photo, its rendering
and attribution still need end-to-end verification before declaring completion.
Do not add arbitrary sample photos or expose provider credentials to work around
the missing metadata.
