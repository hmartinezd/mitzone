# Flutter and QA/accessibility audit

Audit date: 2026-11-03. Scope: read-only source, test definitions, CI configuration, tool paths, and historical image inspection. No app, emulator, tests, builds, remote services, or backend writes were run. This document records evidence and proposals, not an implementation approval or fresh validation result.

## Flutter Developer findings

The existing feature-based presentation/data/domain organization and Riverpod providers should be preserved. Extend shared theme/components after design approval; do not rebuild screens or swap data sources for visual convenience.

| Foundation | Existing evidence | Design decision still needed |
|---|---|---|
| Color | `lib/app/theme/app_colors.dart`, `app_theme.dart`, and `mitzone_theme_colors.dart` supply Material and semantic roles | Approve exact dark navy surfaces and cyan/blue hierarchy. Theme surfaces include neutral `#1E1E1E`, while Home overrides cards to `#101B2B` and background to `#070D15`/`#0B1423`; decide whether these are semantic variants or drift. |
| Typography | `app_typography.dart` defines a full Material scale, 11–57 logical pixels | Approve typeface, screen title/hero hierarchy, metadata minimums, and text-scaling behavior. Home directly specifies 42px; `home_event_section.dart` includes 8px text requiring contextual accessibility review. |
| Spacing and size | `app_spacing.dart` defines 4–64 spacing, 48 minimum interaction dimension, and 400/600/1200 content limits | Approve phone density, carousel width/peek, page padding, large-text layouts, keyboard and landscape behavior across journeys. |
| Shape | `app_radii.dart` defines 4/8/12/16/pill | Home discovery adds 22px, event details 20px, and several features use literal radii. Specify named component variants before normalizing. |
| Components | Shared button, text field, card, badge, feedback, loading, empty state, confirmation dialog, page body/scaffold | Add a documented state/specification matrix, not duplicate widgets: default/focus/pressed/disabled/busy, errors and retry, long content, destructive intent, and screen-reader labels. |
| Page chrome | Shared atmospheric gradient, safe area, scrolling, optional inline title/back control; theme app bars are centered | Decide when centered app bars versus inline left titles are intentional. Standardize navigation hierarchy and return behavior in approved designs. |
| Imagery | Existing real provider event photos, attribution and honest fallbacks; places photo integration is absent | Define crop/overlay/metadata/credit rules and distinguish informational places from tappable events. Generated/stock imagery must not impersonate provider content. |
| Component review | `lib/features/foundation/presentation/visual_system_showcase_screen.dart` exists | Review its coverage against approved specifications; do not treat the showcase as design approval. |

Concrete local overrides occur in `lib/features/home/presentation/home_screen.dart`, `widgets/discovery_section.dart`, `widgets/home_header.dart`, and `lib/features/encounters/presentation/foreground_presence_card.dart`. These demonstrate a reconciliation need; literals alone do not prove a visual defect. Approve a component/token map before replacing them.

Missing design-system documentation includes imagery/attribution rules, icon family/strokes, motion and reduced-motion guidance, content tone and date/time formatting, complete component states, accessibility behavior, and responsive specifications. Retain documented navy/blue/turquoise direction as a proposal constraint while exact values/layouts remain open.

## QA & Accessibility Engineer findings

Existing test definitions provide a useful foundation; no pass/fail claim is made for the current checkout:

- `test/shared/widgets/` covers shared controls, including button busy/disabled behavior and minimum height.
- `test/features/home/presentation/home_screen_test.dart` covers async discovery and social states, retry, real-photo/fallback behavior, navigation, 320×480 through wide layouts, 1×/2× text, and Android tap-target/labeled-target/contrast guidelines for a defined Home state.
- `test/features/profile/profile_responsive_test.dart` covers profile, edit, details and settings across 320×480, 414×896, landscape and tablet; selected 2× text cases; avatar edit target semantics and dimensions.
- Onboarding, splash, password recovery, events, profile navigation and hardening also contain text-scale or responsive checks. Router regression tests and encounter/privacy domain tests should be retained.
- `test/app/theme/contrast_test.dart` checks selected token pairs. Some checks use 3:1; this cannot establish 4.5:1 compliance for normal-size text on actual rendered gradients/photos or all UI states.
- `.github/workflows/flutter_ci.yml` declares formatting, analysis, tests and Android debug APK on Linux, plus tests and unsigned iOS simulator build on macOS, using Flutter 3.44.8. Configuration is not evidence those jobs currently pass.

No `integration_test/` suite or golden-image assertions were found in the inspected repository. Existing tests do not establish all-screen emulator, keyboard, OS permission-dialog, screen-reader, focus-order, dynamic-image contrast, reduced-motion, or real-service integration acceptance. Screenshot checks should complement behavior and semantics tests, not replace them.

### Priorities for approved validation work

1. **P0: safe environment and evidence provenance.** Identify environment and startup write paths before launching. Use approved nonproduction accounts/data for mutating journeys; preserve discovery/presence separation, consent and Stop. Never activate presence/check-in from a simulated location for a screenshot.
2. **P1: whole-app coverage matrix.** Map inventory IDs to applicable success/loading/empty/error/offline/permission/validation/busy/restricted states and device/text-scale combinations; mark unavailable backend states explicitly.
3. **P1: accessibility acceptance across journeys.** Screen-reader names/order and announcements, reachable actions with large text/keyboard, targets, contrast, visible focus, and non-color status meaning. Inspect active/error/destructive variants, not only happy paths.
4. **P1: visual comparison to approved revision.** Capture the unchanged baseline and later approved implementation at identical viewports. No current design reference is approved by this audit.
5. **P2: durable regression coverage.** After approved implementation, add focused behavioral or visual checks for material risks; avoid brittle tests that simply repeat styling constants.

## Emulator screenshot feasibility and protocol

Read-only path inspection found `/opt/homebrew/bin/flutter`, `/opt/homebrew/bin/dart`, `/usr/bin/xcrun`, Xcode's `simctl`, and Android SDK `platform-tools/adb` and `emulator/emulator` under `/Users/josema/Library/Android/sdk/`. `adb` is not on PATH. This establishes installed paths only; versions, runnable devices, boot state, signing, dependency health and screenshot permissions remain unverified. No tooling installation is currently justified by this evidence.

For a later approved capture phase:

1. Confirm an isolated environment and dedicated test accounts, allowed startup calls and data-write boundaries. Record selected device/OS, logical viewport, pixel ratio, orientation, text scale, locale/timezone and app revision. Do not copy credentials into artifacts.
2. Capture the actual running app using Android `adb exec-out screencap -p` or iOS `xcrun simctl io <device> screenshot <path>` once device access is verified. Avoid screen recreation or composite images as implementation evidence.
3. Flutter specialist reproduces the journey and captures each applicable state. QA independently verifies the reproduction and result. Distinguish provider data, test fixtures, and simulated discovery coordinates in the manifest.
4. Use compact and standard phones at 1×/2× text, plus landscape/keyboard/safe-area checks; include both Android and iOS when runnable. Use the same device configuration for approved mockup comparisons. Capture scroll positions and dialogs separately where needed.
5. Record inventory ID, state, design revision, capture timestamp, commit plus uncommitted-change description, data/environment provenance, reproduction steps and findings next to each artifact. Redact personal data in shared copies and retain no secrets.
6. Review side-by-side with approved mockups for hierarchy, spacing, typography, imagery, component state, clipping and interaction affordance. QA records pass/fail/blocked and the reason; Product Designer resolves design fidelity. Screenshots do not prove screen-reader usability or backend authorization.
7. Run change-appropriate analysis/tests/build checks once implementation is authorized. A blocked integration or unavailable state remains blocked, not silently replaced by invented successful data.

### Historical screenshot evidence

Five existing Android captures were found under `.artifacts/home-phase1/` and `.artifacts/home-visual-refinement/`. The refinement `android-home-tampa-live.png` was visually inspected: it shows a dark Home, real-event-style photographic card with Ticketmaster credit, explicit “I'm here” control and existing Home/Events/Matches/Chat/Profile navigation. This image is historical, not a freshly reproduced app state, design approval, proof of current provider health, or evidence that presence was activated.

`docs/home-phase1.md` records an earlier October 14 test run and provider/capture constraints; it also records a temporary external review entrypoint and a discovery-only Tampa observation. Its reported results must not be relabeled current validation. The historical phase document describes photo delivery as blocked; the later refinement image displays photography. That difference calls for fresh provenance/provider validation in the capture phase, without assuming either old result describes today's runtime.

