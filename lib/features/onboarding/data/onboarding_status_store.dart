/// Interface for persisting and retrieving the onboarding completion status.
abstract interface class OnboardingStatusStore {
  /// Returns true if the onboarding has been completed.
  Future<bool> isCompleted();

  /// Marks the onboarding as completed.
  Future<void> markCompleted();
}
