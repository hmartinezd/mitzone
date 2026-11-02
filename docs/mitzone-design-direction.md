# Mitzone visual direction

## Status and scope

This document records the recovered product and visual direction. The original
eight-screen composite and an approved Home screenshot are not currently
available, so this is a design brief, not a pixel-level specification or
approval of exact screen layouts.

The immediate design-review and implementation scope is **Home only**.
Documenting the broader product direction does not authorize implementation of
other screens, new features, navigation changes, or backend changes.

## Confirmed product and visual direction

- Mitzone is a social network connecting people through real-world places,
  activities, and shared moments. It is not primarily an event-organizing app.
- The visual language is premium dark navy / near-black, with electric blue and
  turquoise accents, clean white typography, and generous spacing.
- Home's headline is **“Where will you be?”**
- Home includes a horizontal discovery carousel with large, rounded,
  photographic cards.
- The intended bottom navigation is **Home, Explore, Nearby, Groups, Profile**.
- Matches should emphasize people and the real-world places where their paths
  crossed.
- Nearby should have a radar-inspired visual character without exposing
  people's precise locations.
- Groups are for shared interests and activities.

These are confirmed direction statements, not detailed interaction or layout
specifications for all five destinations.

## Details awaiting visual approval

Until the original reference or a replacement screen design is supplied, the
following remain open:

- Exact Home layout, element order, alignment, card dimensions, carousel
  proportions, and viewport-specific behavior.
- Exact typeface, font sizes, weights, line heights, and text treatments.
- Exact navy, blue, turquoise, surface, border, gradient, and contrast values.
- Photo subject matter, crop, overlays, image-to-text balance, and card content
  hierarchy.
- Corner radii, shadow/border treatment, iconography, and spacing scale.
- Whether the proposed navigation direction replaces the app's current
  **Home, Events, Matches, Chat, Profile** navigation, and how existing routes
  map to any future destinations.
- Detailed behavior and information hierarchy for Explore, Nearby, and Groups.

Do not treat this list as permission to invent missing product requirements.

## Current Home context

The Flutter Home is composed in `lib/features/home/presentation/home_screen.dart`.
It currently combines the personalized header, “Where will you be?” headline
and supporting copy, discovery carousel, explicit foreground-presence controls,
and conditional social-priority content. Discovery presentation is primarily
in `lib/features/home/presentation/widgets/home_discovery.dart` and
`lib/features/home/presentation/widgets/discovery_section.dart`; the shared
page scrolling, safe-area, and padding behavior comes from
`lib/shared/widgets/mitzone_page_body.dart`.

The current Home already has a dark navy treatment, cyan accents, rounded
discovery cards, a horizontal carousel, and the requested headline. Its
existing content and structure are not yet evidence of a match to the
unavailable design reference. In particular, the carousel currently displays
real provider results and honest unavailable-photo placeholders; it must not
be filled with invented events or decorative stock imagery to make a review
screenshot look more complete.

The app's current navigation and existing destinations are still in place.
The new navigation direction, Nearby radar treatment, and Groups are product
direction only; they are not part of the Home-only implementation plan unless
separately approved.

## Focused Home implementation plan

1. **Obtain a visual reference before implementation.** Compare a Home
   screenshot against the supplied approved design at a fixed device size,
   density, orientation, and text scale. Record concrete differences rather
   than inferring exact values from this brief.
2. **Map reference regions to existing components.** Review the header,
   headline/copy, carousel heading and cards, presence panel, social content,
   page insets, and scroll behavior. Prefer adapting the existing Home
   composition and widgets over rebuilding them.
3. **Translate the visual comparison into a Home-only specification.** Identify
   the necessary layout, typography, color, spacing, card, and image-cropping
   adjustments. Keep functional sections and routes unless a separately
   approved design explicitly requires a change.
4. **Use only valid existing image sources.** Continue using HTTPS event image
   URLs returned by the existing event repository and retain source credits.
   Do not add fabricated events, generated/stock photography, or new
   dependencies as substitutes for missing provider images. Keep a clear
   neutral fallback when an image is unavailable.
5. **Preserve behavior and safeguards.** Do not change authentication, Supabase
   integrations, data ownership, provider requests, location permissions, or
   explicit presence consent/writes as part of visual work. Nearby discovery
   remains distinct from explicit presence; never expose or persist precise
   user coordinates for a visual effect.
6. **Validate the approved implementation.** Run focused Home tests and
   analysis, then check responsive layouts, accessibility, text scaling,
   existing routes, and provider loading/error/empty states. Capture an actual
   emulator screenshot and compare it directly with the approved reference
   before considering visual fidelity complete.

## Known technical and content limitations

- The Home phase notes report that the `nearby-events` provider returned HTTP
  502 during the documented review, and that nearby places had no photo data.
  Their cards consequently showed honest photo-unavailable placeholders.
- Google Places photo retrieval is not implemented. Adding it would require a
  separately approved server-side integration, required attribution, and
  review of applicable policies, storage, and costs. Do not add Places photo
  fields, credentials, API calls, deployments, or billing changes as part of
  the Home visual pass.
- A simulated location may be used for provider-only emulator review if
  explicitly approved. It does not establish physical presence; do not invoke
  check-in or “I’m here” for visual verification.
- Without an approved Home image, exact visual differences, image selection,
  and screenshot-based fidelity cannot yet be assessed.
