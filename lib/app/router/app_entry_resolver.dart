import '../../features/onboarding/data/onboarding_status_store.dart';

/// Possible destinations after the application startup/splash sequence.
enum AppEntryTarget {
  /// The user should see the onboarding sequence.
  onboarding,

  /// The user has already completed onboarding.
  ///
  /// This will later map to Home or Login depending on the session.
  /// Currently maps to the development Showcase.
  postOnboarding,
}

/// Resolves where the user should be directed after the splash screen.
class AppEntryResolver {
  const AppEntryResolver(this._onboardingStatusStore);

  final OnboardingStatusStore _onboardingStatusStore;

  /// Determines the next [AppEntryTarget] based on persisted application state.
  Future<AppEntryTarget> resolve() async {
    try {
      final isCompleted = await _onboardingStatusStore.isCompleted();
      return isCompleted
          ? AppEntryTarget.postOnboarding
          : AppEntryTarget.onboarding;
    } catch (e) {
      // In case of read failure, safely default to showing onboarding.
      return AppEntryTarget.onboarding;
    }
  }
}
