# Home restoration — Phase 1

Reference: the product owner's eight-screen `home.png` supplied on 2026-10-14.
Only the Home composition is being restored. Bottom navigation remains
Home / Events / Matches / Chat / Profile. The future navigation direction is
Home / Explore / Nearby / Groups / Profile, with persistent messages access;
that redesign and Groups are not implemented in this phase.

## Design and data

Home uses the existing Mitzone mark, a compact greeting, a permanent
“Where will you be?” headline, the approved supporting copy, dark navy
surfaces, and a large horizontal carousel. Existing social priorities and
routes remain available below discovery and explicit presence controls.

Photographic event cards use only HTTPS image URLs supplied by the existing
event repository, preserving source credits and event-detail navigation with
Home as the return destination. Places retain the current discovery data and
Google attribution. They are informational: no tap handlers, ripple, button
semantics, or invented destination. Missing or failed images show a labelled
neutral placeholder, never stock/generated photography masquerading as a place.
Successful source results remain visible when another source fails.

## Location investigation and correction

“Finding your location…” was presence UI covering both the GPS request and the
subsequent presence server write. The native GPS request had no explicit time
limit. Discovery independently requested another fix and had no request timeout.

Discovery now shares one foreground observation between places and events,
with a 20-second observation boundary and bounded provider requests. Native
GPS acquisition has a 15-second time limit. Permission/location failures do
not retry automatically. Home distinguishes loading location, loading results,
denied permission, permanent denial, disabled services, unavailable location,
remote failure, timeout, and genuinely empty results. Retry explicitly refreshes
the failed queries, including location when needed; Settings is available for
permanent denial/disabled services.

Discovery never calls the presence gateway or changes participation. Explicit
presence obtains its own fresh observation; a late timed-out GPS result cannot
write evidence. Presence UI distinguishes finding a fix from confirming the
server record. Its consent, evidence lifetime, Stop action and server
persistence remain in place. There are no new permissions, streams, background
tracking, coordinate persistence, or fabricated encounters.

## Separate assessment: Google Places photographs — not implemented

The current `nearby-discovery` field mask and normalized response contain no
photos. A future implementation needs a separately approved server integration:
request `places.photos`, preserve photo resource names/author attribution, then
retrieve appropriately sized media. Photo names expire and cannot be cached;
load on demand. Credentials must remain server-side. Display required author
attribution with each photograph. [Official photo API requirements](https://developers.google.com/maps/documentation/places/web-service/place-photos).

Before approval, review Google Maps branding/attribution placement, permitted
storage, and application terms/privacy requirements. Existing Google-sourced
place attribution is retained in Phase 1. [Places policies](https://developers.google.com/maps/documentation/places/web-service/policies).

The published global list checked on 2026-10-14 lists Place Details Photos at
1,000 free monthly billable events, then $7 per 1,000 in the first paid tier.
Nearby Search Pro is separately listed at 5,000 free, then $32 per 1,000.
Illustratively, 10,000 billable photo requests cost $63 for the photo SKU alone
at that tier; searches, other usage, regional terms and taxes are separate.
This is an estimate, not a quote or a claim about the owner's current billing.
Confirm applicable SKUs, field-mask tier, region, quotas, and actual demand
before enabling anything. No field mask, API key, deployment or billing setting
was changed. [Official pricing](https://developers.google.com/maps/billing-and-pricing/pricing).

## Review and validation

Responsive checks cover 320×480, 414×896, landscape and tablet widths with
1×/2× text. Existing Home → Events → Home, Profile, social and chat routes
remain covered. Provider tests use deterministic location and repositories;
no live services or fabricated fallback data are required by the tests.

Android review uses the product-owner-approved simulated Tampa location solely
for querying actual providers. It does not establish physical presence and no
check-in or “I’m here” action is used for the review. Screenshots must identify
live data versus deterministic test states; mock content is not evidence that
production providers work.

Validation on 2026-10-14: `flutter analyze` reports no issues; the complete
`flutter test --reporter expanded` run terminates with 460 passing tests and
zero failures. Home coverage includes the actual dark theme, 320×480 and
414×896 layouts, landscape/tablet, 2× text, navigation and accessibility.

Android screenshots are in `.artifacts/home-phase1/` (local review artifacts,
not committed). `android-tampa-live.png` and `android-tampa-text-200.png` use
actual provider results and a temporary discovery-only Tampa observation;
the native emulator location adapter did not supply a fix. The review
entrypoint lives outside the repository and is not part of the application.
The emulator is returned to the regular `lib/main.dart` entrypoint and 1× text
after capture. No presence action was invoked.

Photographic live review remains blocked: `nearby-events` returns HTTP 502,
while `nearby-discovery` returns real places without photos. Screenshots
therefore show honest photo-unavailable placeholders. The photo rendering,
source credit and failure paths are covered by widget tests, but this is not
proof of successful live photo delivery. No Edge Function, production
configuration or Google Places photo integration was changed. Existing
unrelated `pubspec.lock` modifications remain excluded from this phase.
