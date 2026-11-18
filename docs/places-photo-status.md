# Optional Places photos

Nearby Discovery requests `places.photos` and returns one signed photo reference
per place, with author attribution and the source photo link when available.
References expire after 15 minutes and are bound to the authenticated user. The
discovery response and the photo response use `Cache-Control: private, no-store`.

Valinor discovery cards request media when the user selects **Load place photo**.
The authenticated Edge Function calls Place Photos (New), validates the Google
image URL, and returns bounded image bytes. The provider key stays on the server.
Cards show a loading or unavailable state as appropriate. The client still accepts
safe image URLs from the existing deployed development function.

Nearby Search remains in the Pro tier. Each successful Place Photos (New) media
request is billed separately. The signed-reference flow makes no media requests
during discovery search or scrolling. It requires deployment of
`nearby-discovery` to take effect in the development backend.

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
