# Mitzone

“The best connections begin in the real world.”

Mitzone transforms real-world encounters into meaningful digital connections, helping people reconnect after sharing the same place, event, and moment.

## Project Status

**Current Phase**: Home (Next)

**Completed Phases**:
1. **Foundation Hardening**: Repository cleanup, architecture hardening, testable bootstrap, sanitized logging, and CI/CD.
2. **Visual System and Shared Components**: Design tokens, dark Material 3 theme, reusable UI components, and visual showcase.
3. **Splash Screen**: Reveal sequence with atmospheric motion, native platform launch configuration, and routing foundation.
4. **Onboarding**: Three-page product introduction with custom illustrations, local persistence, and application-entry resolution.
5. **Local Development Identity + Minimum Profile**: Stable local user identity (UUID v4), profile creation (Display Name + Optional Avatar), and managed local storage.
6. **Main Navigation**: Five-destination Material 3 navigation shell using `StatefulShellRoute`, persistent branch state, and responsive navigation bar.

## Application Entry Policy

The long-term application-entry rules are:

1. **Active session + complete minimum profile** → Home (/app/home)
2. **Active session + incomplete minimum profile** → Create Profile
3. **No active session + onboarding previously completed** → Login
4. **First use** → Onboarding

*Note: In the current development stage, a **Local Development Identity** is used instead of a Supabase session to allow rapid feature development without backend dependency.*

## Main Navigation

Mitzone features exactly five primary destinations accessible via a Material 3 bottom navigation bar:
- **Home**: The central discovery dashboard (currently a temporary shell for Phase 6).
- **Events**: Discovery of shared experiences (uses simulated local demo data).
- **Matches**: Connections from shared experiences (currently an intentional empty state).
- **Chat**: Conversations with connections (currently an intentional empty state).
- **Profile**: A read-only preview of the current local development profile.

## Routing Architecture

The application uses `go_router` with `StatefulShellRoute.indexedStack` to provide:
- Persistent state across navigation branches.
- Independent navigation stacks for each destination.
- Support for future deep linking and nested routes.

## Local Development Identity

Mitzone currently uses a persistent, locally generated identity to represent the user during development.
- **Identity ID**: A stable UUID v4 generated once upon onboarding completion.
- **Storage**: Persisted in `SharedPreferences` as `local_identity.id.v1`.
- **Purpose**: Provides a stable identifier for profile ownership and future feature data (events, matches) while remaining decoupled from the future Supabase implementation.

## Minimum Profile

Users must complete a minimal profile before entering the main application.
- **Display Name**: Required, 2-50 characters. Supports international characters.
- **Profile Photo**: Optional. Selected from gallery and copied to managed application storage.

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

## Development Setup

### Prerequisites
- Flutter SDK (Stable)
- Android Studio / Xcode

## Running the Application

### Initial Route
The application launches into the **Splash Screen** (`/`), which resolves the destination via `AppEntryResolver`.

```bash
flutter run
```

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
    └── profile/          # User profile management
```

## Planned Order of Implementation

1. Foundation hardening (Completed)
2. Visual system and shared components (Completed)
3. Splash Screen (Completed)
4. Onboarding (Completed)
5. Local Development Identity + Minimum Profile (Completed)
6. Main Navigation (Completed)
7. Home (Next)
8. Profile and Settings
9. Permanent Authentication (Deferred)
10. Supabase Backend Integration (Deferred)
