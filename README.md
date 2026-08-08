# Mitzone

“The best connections begin in the real world.”

Mitzone transforms real-world encounters into meaningful digital connections, helping people reconnect after sharing the same place, event, and moment.

## Project Status

**Current Phase**: Authentication (Next)

**Completed Phases**:
1. **Foundation Hardening**: Repository cleanup, architecture hardening, testable bootstrap, sanitized logging, and CI/CD.
2. **Visual System and Shared Components**: Design tokens, dark Material 3 theme, reusable UI components, and visual showcase.
3. **Splash Screen**: Reveal sequence with atmospheric motion, native platform launch configuration, and routing foundation.
4. **Onboarding**: Three-page product introduction with custom illustrations, local persistence using `shared_preferences`, and application-entry resolution.

## Application Entry Policy

The long-term application-entry rules are:

1. **Active session + complete minimum profile** → Home
2. **Active session + incomplete minimum profile** → Create Profile
3. **No active session + onboarding previously completed** → Login
4. **First use** → Onboarding

*Note: Until Authentication is implemented, users who have completed Onboarding temporarily continue to the Visual System Showcase.*

## Visual System

Mitzone uses a modern, minimalist, dark-first visual language designed to communicate connection and discovery.

### Design Tokens
- **Colors**: Near-black navy background, bright cyan primary, electric blue secondary, and purple accents.
- **Typography**: Complete Material 3 `TextTheme` using system fonts for maximum reliability and accessibility.
- **Spacing**: Predictable scale (4, 8, 12, 16, 20, 24, 32, 40, 48, 64).
- **Radii**: Small, medium, large, extra-large, and pill.

### Shared Components
Reusable components are located in `lib/shared/widgets/` and include:
- `MitzonePageScaffold`: Responsive layout foundation with atmospheric gradients and configurable AppBar.
- `MitzoneBrand`: Code-based temporary brand mark and logo presentation.
- `MitzoneButton`: Support for primary, secondary, tertiary, and destructive variants with loading states.
- `MitzoneTextField`: Standardized inputs with validation and visibility toggles.
- `MitzoneCard`: Semantic surfaces for content grouping.
- `MitzoneStatusBadge`: Iconic status indicators (Neutral, Info, Success, Warning, Error).
- `MitzoneFeedbackBanner`: Contextual feedback for user operations.
- `MitzoneLoadingIndicator`: Spinners with optional descriptive text.
- `MitzoneEmptyState`: Centered layouts for missing content.
- `MitzoneConfirmationDialog`: Helper for destructive or important actions.

### Implementation Guidelines
- **Theme Usage**: Use `Theme.of(context)` to access colors and text styles.
- **Semantic Colors**: Use `Theme.of(context).extension<MitzoneThemeColors>()` for brand-specific colors and semantic roles (success, warning, info).
- **Accessibility**: All interactive targets are at least 48x48. Large text scaling (2.0+) is supported without clipping or overflow. Contrast pairs are verified to meet WCAG standards.
- **Motion**: Accessibility motion preferences are respected using `MediaQuery.disableAnimations`.

## Technical Specifications

- **Flutter SDK**: 3.44.8 (Channel stable)
- **Dart SDK**: 3.12.2
- **Platforms**: Android, iOS
- **Main Dependencies**:
  - `flutter_riverpod`: ^3.4.2
  - `go_router`: ^17.4.0
  - `supabase_flutter`: ^2.17.1
  - `shared_preferences`: ^2.5.5

## Development Setup

### Prerequisites
- Flutter SDK (Stable)
- Android Studio / VS Code
- Xcode (for iOS development)
- CocoaPods (for iOS plugins)

### Android Setup
1. Ensure Android SDK and Command-line Tools are installed.
2. Run `flutter doctor --android-licenses` to accept licenses.

### iOS Setup
1. Ensure Xcode is installed and selected:
   ```bash
   sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
   sudo xcodebuild -runFirstLaunch
   ```
2. Install CocoaPods: `brew install cocoapods`.

## Running the Application

### Initial Route
The application launches into the **Splash Screen** (`/`), which resolves the next destination via `AppEntryResolver`. First-time users are directed to **Onboarding** (`/onboarding`).

```bash
flutter run
```

### With Environment Configuration
Create a configuration file (e.g., `config/dev.json`):
```json
{
  "APP_ENV": "development",
  "SUPABASE_URL": "https://YOUR_PROJECT.supabase.co",
  "SUPABASE_PUBLISHABLE_KEY": "YOUR_PUBLISHABLE_KEY"
}
```
Run with the configuration:
```bash
flutter run --dart-define-from-file=config/dev.json
```

## Quality and Validation

### Format Code
```bash
dart format .
```

### Static Analysis
```bash
flutter analyze
```

### Run Tests
```bash
flutter test
```

## Build Commands

### Android Debug APK
```bash
flutter build apk --debug
```

### iOS Simulator build (no signing required)
```bash
flutter build ios --simulator
```

## Project Structure
```
lib/
├── main.dart             # Entry point
├── bootstrap.dart        # Initialization logic
├── app/                  # Global app configuration
│   ├── router/           # Routing and entry resolution
│   └── theme/            # Design tokens and Material theme
├── core/                 # Shared utilities, config, and providers
├── shared/               # Reusable UI components
└── features/             # Feature-specific code
    ├── foundation/       # Foundation showcase and failure screens
    ├── splash/           # Splash screen and entry animation
    └── onboarding/       # Product onboarding and local state
```

## Planned Order of Implementation

1. Foundation hardening (Completed)
2. Visual system and shared components (Completed)
3. Splash Screen (Completed)
4. Onboarding (Completed)
5. Email/password authentication (Next)
6. Email verification
7. Minimum profile
8. Main navigation
9. Home
10. Profile and Settings
