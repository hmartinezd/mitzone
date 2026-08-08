# Mitzone

“The best connections begin in the real world.”

Mitzone transforms real-world encounters into meaningful digital connections, helping people reconnect after sharing the same place, event, and moment.

## Project Status

**Current Phase**: Sprint 1 Local Demo Hardening (Completed)

**Completed Phases**:
1. **Foundation Hardening**: Repository cleanup, architecture hardening, testable bootstrap, sanitized logging, and CI/CD.
2. **Visual System and Shared Components**: Design tokens, dark Material 3 theme, reusable UI components, and visual showcase.
3. **Splash Screen**: Reveal sequence with atmospheric motion, native platform launch configuration, and routing foundation.
4. **Onboarding**: Three-page product introduction with custom illustrations, local persistence, and application-entry resolution.
5. **Local Development Identity + Minimum Profile**: Stable local user identity (UUID v4), profile creation (Display Name + Optional Avatar), and managed local storage.
6. **Main Navigation**: Five-destination Material 3 navigation shell using `StatefulShellRoute`, persistent branch state, and responsive navigation bar.
7. **Full Home Experience**: Personalized discovery dashboard with curated demo events, matches empty state, and product education.
8. **Profile and Settings**: Fully functional local profile management, derived completion percentage, and comprehensive Settings navigation structure.
9. **Sprint 1 Local Demo Hardening**: Robust async profile loading, removal of nested scaffolds, centralized validation, improved accessibility, and safe avatar replacement.

**Upcoming Phases**:
10. **Permanent Authentication** (Deferred)
11. **Supabase Backend Integration** (Deferred)

## Application Entry Policy

The long-term application-entry rules are:

1. **Active session + complete minimum profile** → Home (/app/home)
2. **Active session + incomplete minimum profile** → Create Profile
3. **No active session + onboarding previously completed** → Login
4. **First use** → Onboarding

*Note: In the current development stage, a **Local Development Identity** is used instead of a Supabase session to allow rapid feature development without backend dependency.*

## Main Navigation

Mitzone features exactly five primary destinations accessible via a Material 3 bottom navigation bar:
- **Home**: The central discovery dashboard. Features personalized greeting and curated discovery sections.
- **Events**: Discovery of shared experiences (uses simulated local demo data).
- **Matches**: Connections from shared experiences (currently an intentional empty state).
- **Chat**: Conversations with connections (currently an intentional empty state).
- **Profile**: Functional profile management and application settings.

## Profile and Settings

Users can manage their local profile and access application settings.
- **Editable Profile**: Change display name and profile photo with safe replacement strategy.
- **Progressive Details**: Optional fields including bio, city, languages, interests, and connection goals (Social, Professional, Both).
- **Profile Completion**: Informational percentage derived from seven profile components.
- **Settings**: Structured navigation for Account, Privacy, Notifications, and Legal.
- **Note on Account Actions**: Sign Out and Delete Account actions are visibly deferred until permanent authentication is implemented, as the current identity is local-only.

## Local Demo Boundary

For this development phase, the following boundaries apply:

### Works
- Persistent local identity and profile across restarts.
- Full main navigation with tab state preservation.
- Robust profile editing with async safety and validation.
- Responsive layouts (320px to Tablet) and accessibility (2.0 text scale).
- Local avatar storage with safe replacement and fallback.
- Personalized discovery dashboard with demo content.

### Intentionally Deferred
- **Authentication**: Permanent accounts, sign-out, and deletion are unavailable.
- **Real Backend**: All data is local; Supabase is integrated but inactive.
- **QR/Location**: Scanner and GPS functionality are not implemented.
- **Dynamic Content**: Events, Matches, and Chat remain deterministic demo states.
- **Web**: Only Android/iOS platforms are currently targeted.

## Local Development Identity

Mitzone currently uses a persistent, locally generated identity to represent the user during development.
- **Identity ID**: A stable UUID v4 generated once upon onboarding completion.
- **Storage**: Persisted in `SharedPreferences` as `local_identity.id.v1`.
- **Purpose**: Provides a stable identifier for profile ownership and future feature data while remaining decoupled from the future Supabase implementation.

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
    └── events/           # Event discovery
```
