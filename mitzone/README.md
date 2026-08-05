# Mitzone

“The best connections begin in the real world.”

Mitzone is a mobile application designed to foster authentic real-world connections. This project establishes the initial technical foundation for the application.

## Foundation Phase Scope

This phase focuses on setting up the core architecture and infrastructure:
- Flutter project initialization for Android and iOS.
- Core architecture: Features, Core, and App layers.
- Dependency injection and state management with Riverpod.
- Declarative navigation with GoRouter.
- Environment configuration via `--dart-define`.
- Supabase SDK integration (initialization only).
- Branded Foundation Screen with theme configuration.
- Basic unit and widget tests.

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

### Without Supabase (Local/Default)
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

**Note**: `SUPABASE_PUBLISHABLE_KEY` is a client-side key. **Never** include secret or service-role keys in the application.

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

### iOS Simulator Build
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

## Next Phase
**Sprint 1: Authentication & User Profiles**
- Implementation of Supabase Auth (Email/OTP).
- Onboarding flow and profile creation.
- Secure storage of session tokens.
