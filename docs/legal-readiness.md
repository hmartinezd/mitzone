# Legal and privacy readiness

## Code complete

The MVP now provides in-app Terms and Privacy Policy access from Settings,
explicit foreground-presence disclosure, account deletion access, and current
data-practice documentation. The actual active providers are Supabase
(authentication, profile and configured backend records) and Firebase
(Analytics, Crashlytics and Cloud Messaging). Google Places and Ticketmaster
are not current app data recipients.

The MVP may process authentication email, user-supplied profile data, local or
backend presence/discovery records, connections, conversations/messages,
reports/blocks, device tokens, and limited aggregate observability data.
Analytics and crash reports exclude exact location, message/report contents,
credentials, tokens, email/phone and unnecessary profile PII.

Account deletion calls the authenticated `delete-account` function. The schema
uses cascading ownership for profiles, presence evidence, relationships,
conversations/messages and device tokens; reports/blocks are reviewed by their
foreign-key policies and may be retained only where safety/legal handling
requires it. Local demo data is device storage and is not remotely deleted.

## Manual / business / legal review required before public release

- Legal entity name, privacy/support contact and business address.
- Final minimum-age and minor policy.
- Governing law/jurisdiction and liability language.
- Production HTTPS Privacy Policy URL and Terms URL.
- Retention schedule and privacy-rights request workflow.
- Apple App Privacy labels and Google Play Data Safety declarations.
- Location permission disclosures and account-deletion store compliance review.
- UGC moderation/support process and store declarations.
- Final Firebase/Supabase runtime configuration and real-device validation.

Store checklist: publish policy URLs and support contact; declare account,
profile, location/presence, messages, identifiers, diagnostics and push data
accurately; explain foreground location before permission; verify deletion
works in the submitted build; and document reporting/blocking for social UGC.
