# Mitzone

“The best connections begin in the real world.”

Mitzone transforms real-world encounters into meaningful digital connections, helping people reconnect after sharing the same place, event, and moment.

## Project Status

**Current Phase**: Sprint 3 — Supabase authentication/profile slice implemented; broader backend architecture remains deferred

**Baseline**: Sprint 1 local/offline demo — closed and validated. This is a
demo baseline, not a production-readiness claim.

**Completed Phases**:
1. **Foundation Hardening**: Repository cleanup, architecture hardening, testable bootstrap, sanitized logging, and CI/CD.
2. **Visual System and Shared Components**: Design tokens, dark Material 3 theme, reusable UI components, and visual showcase.
3. **Splash Screen**: Reveal sequence with atmospheric motion, native platform launch configuration, and routing foundation.
4. **Onboarding**: Three-page product introduction with custom illustrations, local persistence, and application-entry resolution.
5. **Local Development Identity + Minimum Profile**: Stable local user identity (UUID v4), profile creation (Display Name + Optional Avatar), and managed local storage.
6. **Main Navigation**: Five-destination Material 3 navigation shell using `StatefulShellRoute`, persistent branch state, and responsive navigation bar.
7. **Connected Home Experience**: Personalized discovery dashboard with curated demo events and live summaries of local encounters, requests, connections, and conversations.
8. **Profile and Settings**: Fully functional local profile management, derived completion percentage, and comprehensive Settings navigation structure.
9. **Sprint 1 Local Demo Hardening**: Robust async profile loading, removal of nested scaffolds, centralized validation, improved accessibility, corruption-safe local persistence, and transactional avatar replacement.
10. **Event Experience & Local Participation Foundation — Complete**: Event details, stable local catalog IDs, identity-scoped participation, and participation-aware upcoming activities.
11. **Supabase Authentication + Minimum Profile**: Email/password sign in and sign up, session restoration, explicit email-confirmation handling, and authenticated profile creation owned by the Supabase user UUID.

**Future / Deferred**:
- **Password Recovery and Email-Confirmation Deep Links — Future**
- **Account Deletion and Production Account Management — Future**
- **Supabase Social-Feature Synchronization — Deferred**
- **Verified Event Presence — Future**
- **Production Matching — Future**
- **QR Check-in — Future**
- **Geolocation — Future**

## Application Entry Policy

### Canonical Supabase runtime

Mitzone's normal application runtime is Supabase-backed authenticated mode.
Missing or invalid configuration is a startup error; it never activates a
local identity or demo login. The app supports email/password sign in, account
creation, session restoration, email-confirmation-required signup states, and
authenticated minimum-profile creation. Profiles are keyed by the authenticated
Supabase `auth.users.id`.

The long-term application-entry rules are:

1. **Active session + complete minimum profile** → Home (/app/home)
2. **Active session + incomplete minimum profile** → Create Profile
3. **No active session + onboarding previously completed** → Login
4. **First use** → Onboarding

Social repositories may still use deterministic local/demo data while their
Supabase migrations are unfinished, but they do not provide an authentication
bypass.

## Normal development

In VS Code, press **Run / F5** and choose the single **Mitzone** launch target.
It automatically uses `config/dev.json`.

The equivalent CLI command is:

```bash
flutter run --dart-define-from-file=config/dev.json
```

For first setup:

1. Copy `config/dev.example.json` to `config/dev.json`.
2. Fill in the Supabase project URL and publishable key.
3. Press **F5**.

`config/dev.json` is local and ignored by Git. Use only the client-safe
publishable key; never add a service-role key, database password, JWT signing
secret, or management token to Flutter configuration.

## Main Navigation

Mitzone features exactly five primary destinations accessible via a Material 3 bottom navigation bar:
- **Home**: The central discovery dashboard. Features personalized greeting and curated discovery sections.
- **Events**: Interactive discovery and details backed by deterministic demo data, with local participation.
- **Matches**: Encounters derived from shared event presence, plus local connection-request management.
- **Chat**: Local conversations and messages between established connections.
- **Profile**: Functional profile management and application settings.

## Profile and Settings

Users can manage their application profile and access application settings.
- **Editable Profile**: Change display name and profile photo with safe replacement strategy.
- **Progressive Details**: Optional fields including bio, city, languages, interests, and connection goals (Social, Professional, Both).
- **Profile Completion**: Informational percentage derived from seven profile components.
- **Settings**: Structured navigation for Account, Privacy, Notifications, and Legal.
- **Note on Account Actions**: Sign out is available in configured Supabase mode. Password recovery, email-confirmation deep-link return, and Delete Account remain deferred.

## Local Demo Boundary

For this development phase, the following boundaries apply:

### Works
- Persistent local identity and profile across restarts.
- Full main navigation with tab state preservation.
- Robust profile editing with async safety and validation.
- Responsive layouts (320px to Tablet) and accessibility (2.0 text scale).
- Local avatar storage with safe replacement and fallback.
- Personalized discovery dashboard with demo content.
- Identity-scoped event participation persisted as event IDs under `local_event_participation.v1.<identityId>`.
- Upcoming activities synchronized with joined events without restarting.
- Local/demo check-in presence and deterministic encounters derived from real interval overlap.
- Local contextual connection requests and established connections.
- Authorized local conversations and messages between active connections.
- Home summaries that react to encounters, incoming requests, connections, and recent conversations.

### Intentionally Deferred
- **Supabase social backend synchronization — Deferred**: Events, encounters, requests, connections, conversations, and messages remain local/demo data.
- **Verified Event Presence — Future**: Participation records intent only and never claims verified attendance.
- **Production Matching — Future**: Encounter data is a deterministic local demo, not a production recommendation or matching system.
- **QR Check-in — Future**: Scanner functionality is not implemented.
- **Geolocation — Future**: GPS functionality is not implemented.
- **Event Content**: The catalog remains deterministic demo data; participation is local intent, not verified presence.
- **Backend Sync**: Encounters, requests, connections, conversations, and messages remain local to the device.
- **Web**: Only Android/iOS platforms are currently targeted.

## Local/demo data boundary

Mitzone may retain local repositories, deterministic fixtures, and explicit
test-only local identities for unfinished social-domain migration and
automated tests. These are not a normal application runtime and are not
selected by plain `flutter run`.
- **Identity ID**: A stable UUID v4 generated once upon onboarding completion.
- **Storage**: Persisted in `SharedPreferences` as `local_identity.id.v1`.
- **Purpose**: Supports explicit local fixtures/tests while remaining separate
  from the Supabase-authenticated application identity.

## Visual System

Mitzone uses a modern, minimalist, dark-first visual language.

### Implementation Guidelines
- **Theme Usage**: Use `Theme.of(context)` for colors and typography.
- **Accessibility**: All interactive targets are at least 48x48. Large text scaling (2.0+) and reduced motion are supported.
- **Abstractions**: UI components depend on `IdentityGateway` and `ProfileRepository` abstractions to facilitate future migration to Supabase.

## Technical Specifications

- **Flutter SDK**: 3.44.8 (Channel stable)
- **Dart SDK**: 3.12.2
- **Platforms**: Android, iOS
- **Main Dependencies**:
  - `flutter_riverpod`: ^3.4.2
  - `go_router`: ^17.4.0
  - `shared_preferences`: ^2.5.5
  - `uuid`: ^4.6.0
  - `image_picker`: ^1.2.3
  - `path_provider`: ^2.1.6

## Quality and Validation

### Format, Analyze, and Test
```bash
dart format .
flutter analyze
flutter test
```

## Build Commands

### Android Debug APK
```bash
flutter build apk --debug
```

### iOS Simulator build
```bash
flutter build ios --simulator
```

## Project Structure
```
lib/
├── app/                  # Global app configuration (router, theme)
├── core/                 # Shared utilities, storage, and identity
├── shared/               # Reusable UI components
└── features/             # Feature-specific code
    ├── foundation/       # Showcase and failure screens
    ├── splash/           # Splash animation
    ├── onboarding/       # Product onboarding
    ├── home/             # Discovery dashboard
    ├── profile/          # User profile management
    ├── events/           # Event discovery and local participation
    ├── encounters/       # Presence-overlap encounter generation
    ├── connections/      # Local requests and connections
    └── chat/             # Authorized local conversations/messages
```
## Local presence

## Sprint 3 backend/auth foundation

Supabase configuration and a backend-neutral authentication contract are now
present. Normal development uses the VS Code **Mitzone** launch target or the
equivalent `flutter run --dart-define-from-file=config/dev.json` command.
`APP_ENV`, `SUPABASE_URL`, and `SUPABASE_PUBLISHABLE_KEY` are required for
development, staging, and production. Missing, partial, or invalid values fail
startup instead of selecting local/demo identity. Never use a service-role key,
database password, JWT signing secret, or management token in the client.

The supported configured flow is: email/password sign in or sign up → active-session check → authenticated minimum-profile creation when needed → Home. When email confirmation is enabled, signup shows a Check your email state and returns to Sign In without creating a local or remote profile row. Password recovery, confirmation deep-link return, account deletion, and Supabase synchronization for the social domains remain deferred.

In the local demo, participation means intending to attend an event, while presence/check-in represents demo attendance. Presence is scoped to the active mock identity. Deterministic mock attendee windows are generated relative to the local check-in, and encounters are derived from genuine interval overlap. QR, geolocation, and independently verified presence remain future work.

The working local flow is: participation → presence → encounter → “Say Hi” request → connection → conversation → messages. These records are local demo data; permanent authentication, backend synchronization, and production presence verification are not implemented.

The active user's encounters use their real local identity-scoped check-ins; other users remain deterministic development fixtures.

## Sprint 2 status

Sprint 2 is formally complete. The supported local flow is event discovery → participation → demo presence → encounter → other-user profile → Say Hi → request → connection → conversation → messages → local notifications → disconnect/block.

The local safety primitives are connection removal by either participant, directional blocking with symmetric interaction restrictions, and authorized chat. Report User and moderation remain explicitly deferred. The production-boundary plan for Sprint 3 is documented in [docs/sprint_3_architecture.md](docs/sprint_3_architecture.md).
