# Implementation Plan: Foundation Hardening Correction Pass

Perform a focused correction pass for the Foundation Hardening phase, improving testability, security, and structure of the Mitzone Flutter project.

## User Review Required

> [!IMPORTANT]
> - `AppConfig` will now have a private constructor, breaking any direct instantiation outside of the class. All production and test code will be updated.
> - `bootstrap` function signature will change to support lightweight dependency injection for testing.
> - GitHub Actions will now cancel in-progress runs on the same branch to save resources.

## Proposed Changes

### [Core Configuration]

#### [MODIFY] [app_config.dart](file:///Users/hector/Projects/MitZone/lib/core/config/app_config.dart)
- Change public constructor to private `AppConfig._`.
- Update `AppConfig.validated` and `AppConfig.fromEnvironment` to use the private constructor.
- Enhance validation to handle more edge cases (whitespace, URI schemes, etc.).
- Ensure `toString()` and error messages never reveal the `supabasePublishableKey`.

### [Application Bootstrap]

#### [MODIFY] [bootstrap.dart](file:///Users/hector/Projects/MitZone/lib/bootstrap.dart)
- Define `AppConfigLoader`, `SupabaseInitializer`, and `AppRunner` typedefs.
- Update `bootstrap` to accept these as optional parameters.
- Call `WidgetsFlutterBinding.ensureInitialized()` within `bootstrap`.
- Sanitize logging: debug-only, no raw exceptions, no credentials.

### [Startup Failure Architecture]

#### [NEW] [startup_failure_screen.dart](file:///Users/hector/Projects/MitZone/lib/features/foundation/presentation/startup_failure_screen.dart)
- Dedicated scrollable screen for startup failures.
- Displays friendly message and a retry button (if callback provided).
- Uses semantic theme colors instead of hardcoded `Colors.redAccent`.

#### [MODIFY] [startup_failure_app.dart](file:///Users/hector/Projects/MitZone/lib/app/startup_failure_app.dart)
- Use `StartupFailureScreen` as the home widget.
- Support an optional `onRetry` callback.

### [Routing]

#### [MODIFY] [app_router.dart](file:///Users/hector/Projects/MitZone/lib/app/router/app_router.dart)
- Extract `createAppRouter` factory.
- Provider now delegates to this factory.

#### [MODIFY] [route_error_screen.dart](file:///Users/hector/Projects/MitZone/lib/features/foundation/presentation/route_error_screen.dart)
- Sanitize error display (no `toString()`).
- Add width constraints and ensure scroll-safety.

### [Foundation Feature]

#### [MODIFY] [foundation_screen.dart](file:///Users/hector/Projects/MitZone/lib/features/foundation/presentation/foundation_screen.dart)
- Remove `IntrinsicHeight` and `Spacer`.
- Improve layout responsiveness (scrolling, max-width on large screens).
- Use semantic colors from `AppColors` for status tiles.

### [Theme and Colors]

#### [MODIFY] [app_colors.dart](file:///Users/hector/Projects/MitZone/lib/app/theme/app_colors.dart)
- Ensure semantic colors are clearly defined and used.

### [CI/CD]

#### [MODIFY] [flutter_ci.yml](file:///.github/workflows/flutter_ci.yml)
- Add `concurrency` block with `cancel-in-progress: true`.
- Update macOS job to include `flutter test`.
- Ensure all required steps (format, analyze, test, build) are present in appropriate jobs.

### [Project Documentation and Metadata]

#### [MODIFY] [README.md](file:///Users/hector/Projects/MitZone/README.md)
- Update product description to: "Mitzone transforms real-world encounters into meaningful digital connections, helping people reconnect after sharing the same place, event, and moment."
- Update phase status and implementation order.

#### [MODIFY] [pubspec.yaml](file:///Users/hector/Projects/MitZone/pubspec.yaml)
- Update description.

### [Testing]

#### [MODIFY] [app_config_test.dart](file:///Users/hector/Projects/MitZone/test/core/config/app_config_test.dart)
- Update to reflect private constructor.
- Add exhaustive validation tests.

#### [MODIFY] [bootstrap_test.dart](file:///Users/hector/Projects/MitZone/test/bootstrap_test.dart)
- Complete rewrite using the new injection seams.
- Test unconfigured, configured, initialization failure, and loader failure paths.

#### [MODIFY] [app_test.dart](file:///Users/hector/Projects/MitZone/test/app/app_test.dart)
- Implement a real unknown-route test using `go_router` through `MitzoneApp`.

## Verification Plan

### Automated Tests
- Run `flutter test` to execute all unit and widget tests.
- Verify `flutter analyze` passes.
- Verify `dart format --output=none --set-exit-if-changed .` passes.

### Build Verification
- Run `flutter build apk --debug`.
- Run `flutter build ios --simulator`.

### Manual Verification
- Verify the Foundation Screen layout on small and large screen dimensions (simulators).
- Verify the Startup Failure UI by forcing a failure in `main.dart`.
- Verify the Route Error Screen by navigating to an unknown path in the simulator.
