# Mitzone

“The best connections begin in the real world.”

Mitzone transforms real-world encounters into meaningful digital connections, helping people reconnect after sharing the same place, event, and moment.

## Project Status

**Current Phase**: Visual system and shared components (Next)

**Completed Phases**:
- **Foundation Hardening**: Repository cleanup, architecture hardening, testable bootstrap, sanitized logging, and CI/CD.

## Technical Specifications

- **Flutter SDK**: 3.44.8 (Channel stable)
- **Dart SDK**: 3.12.2
- **Platforms**: Android, iOS
- **Main Dependencies**:
  - `flutter_riverpod`: ^3.4.2
  - `go_router`: ^17.4.0
  - `supabase_flutter`: ^2.17.1

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

### Commands run directly from the repository root:

#### Without Supabase (Local/Default)
```bash
flutter pub get
flutter run
```

#### With Environment Configuration
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

**Note**: `SUPABASE_PUBLISHABLE_KEY` is a client-side project key. **Never** include secret or service-role keys in the application.

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
├── app/                  # Global app configuration (router, theme)
├── core/                 # Shared utilities, config, and providers
└── features/             # Feature-specific code
    └── foundation/       # Initial foundation screen
```

## Planned Order of Implementation

1. Foundation hardening (Completed)
2. Visual system and shared components (Current)
3. Splash Screen
4. Onboarding
5. Email/password authentication
6. Email verification
7. Minimum profile
8. Main navigation
9. Home
10. Profile and Settings

*Note: Splash, Onboarding, authentication, matching, chat, QR, and geolocation are not yet implemented.*
