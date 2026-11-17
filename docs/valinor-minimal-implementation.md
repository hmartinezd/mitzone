# Valinor Minimal implementation

Local work in `/Users/josema/Projects/mitzone-recovered`, branch
`recovery/mitzone-beta-2026-11`, as requested for this visual pass. Canonical
`/Users/josema/Projects/mitzone` and its main branch have not been changed by this
pass. No merge into main, backend deployment or migration is included. The owner subsequently authorized committing and publishing this visual pass on the recovery branch.

## Saved design references

Project: https://stitch.withgoogle.com/projects/1169891625207640647

- Valinor Minimal: Serene Home — screen `5aba21c111054cbaa13a3f24e2338282`.
- Valinor Minimal: Connected Discovery — screen `b008ee911f504ff8aab6be6c2f74976f`.
- Valinor Minimal: Event & Consent — screen `0eed89cb5c7c4b50a9d73221f76d6a2f`.
- Saved design system: Undying Realm, asset `8001960809454e4b83d0b5ab51eb840b`, version1.

Current HTML exports and the source manifest are preserved under ignored
`.artifacts/valinor-reference/`. The actual saved screenshot references were
retrieved/read; no new designs were generated or written to Stitch.

## Implemented

- Ivory #FAF9F6, solar gold #D4AF37, blue #376284 and blue-gray #466274.
  Gold's darker #735C00 role is used for readable text on ivory, with dark text
  on gold-filled actions. EB Garamond headings and Plus Jakarta Sans body type;
  added hash-verified official EB Garamond400/500/600 assets and the OFL notice.
- Smaller Home introduction, quiet low-activity guidance, simpler header and
  preserved profile/messages actions. Existing actual social/error states remain.
- Compact Explore search and All/Places/Activities filters. Search operates on
  currently loaded provider titles, locations and categories; it is not a new
  global/geocoded provider search. No duplicate network query per keystroke.
- Consistent16:9image areas on place/activity cards, essential title/location/
  distance/date metadata, real source/photo credits and honest missing-photo
  states. Distinct provider errors do not hide successfully loaded items.
- Event256pxhero, actual venue/time metadata, separate attendance-intent action
  and coarse foreground-presence controls. Details/source link are disclosed
  through About; image attribution remains visible. Explore's event push/back
  returns to Explore; Home's existing event/back behavior is preserved.
- Presence retains explicit consent, account-scoped preferences, its existing
  thirty-minute lease, foreground/visibility gates, expiry and failed-Stop
  warning. Active/Retry Stop is a full-width red48px-minimum action above optional
  feedback. Detailed privacy help is contextual; essential boundaries stay visible.
- Home and detail mount presence controls only when visible, preventing retained
  branches from keeping duplicate refreshers or stale Stop UI. Restore does not
  resume collection automatically. Configured debug details do not show mock
  attendee diagnostics. Local demo fixtures remain explicitly local/demo.

## Intentional differences and remaining limits

- Existing five tabs and top Messages access are preserved; the four-tab
  navigation pictured in the illustrative Stitch mockup was not substituted.
- No Private & Verified, attendee-count, capacity, open-floor or venue-verification
  claims. The real presence window is30minutes, not the mockup's2.5hours.
- No illustrative Stitch people/events/photos were inserted into live results.
  Ticketmaster imageUrl/photo attribution is supported. The recovered Google
  contract does not request/parse place photos, so those cards use an explicit
  Photo unavailable state. Filling them needs separately reviewed provider-photo
  support; no new paid requests or backend changes were introduced.
- Places remain informational; no fake View Place, Share or attendance action was
  added. Empty/loading/auth/location/provider errors remain distinct.
- Live event dates/titles remain exactly provider data. This pass does not certify
  provider freshness or change the upstream event search window.

## Validation and evidence

See ignored `.artifacts/valinor-reference/` for full-suite/analyzer/build results,
font provenance, compiled-config verification and nonpersonal Android captures.
New tests cover compact2xtext, functional discovery filters/search, metadata/
photo honesty, deduplicated credits and actual-router presence/Stop cross-screen
behavior. Attendance intent never records presence in those tests.

The Android candidate uses an ignored private copy of the existing authorized
`dev.json`, with the original dev project and client publishable key; no provider
keys or service-role keys are embedded. The APK font manifest and actual font
bytes were independently checked. Existing Firebase platform configuration is
absent, and push was not enabled.

Live Android review after the owner's sign-in confirmed the Valinor candidate
hash, real Ticketmaster card imagery, Explore and Event Detail rendering and the
separate consent/active Stop presentation. No attendance or presence action was
pressed for this review. Captures avoid personal greeting/email fields. Tests
also exercise2xtext and compact layouts; TalkBack and full manual keyboard/focus
review are not represented as completed.

The iOS build remains blocked by the previously established Xcode/Swift dependency
incompatibility; dependencies were not downgraded for this visual pass.
