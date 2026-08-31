import '../../core/identity/identity_gateway.dart';
import '../../features/onboarding/data/onboarding_status_store.dart';
import '../../features/profile/data/profile_repository.dart';
import '../../features/profile/domain/profile_validation.dart';
import '../../core/auth/auth_repository.dart';

/// Possible destinations after the application startup/splash sequence.
enum AppEntryTarget {
  /// The user should see the onboarding sequence.
  onboarding,

  /// The user needs to create a minimum profile.
  createProfile,

  /// The application is ready for use (post-profile).
  ready,

  /// A critical failure occurred during entry resolution.
  entryFailure,
  unauthenticated,
}

/// Resolves where the user should be directed after the splash screen.
class AppEntryResolver {
  const AppEntryResolver({
    required this.onboardingStatusStore,
    required this.identityGateway,
    required this.profileRepository,
    this.authRepository,
  });

  final OnboardingStatusStore onboardingStatusStore;
  final IdentityGateway identityGateway;
  final ProfileRepository profileRepository;
  final AuthRepository? authRepository;

  /// Determines the next [AppEntryTarget] based on application and backend state.
  Future<AppEntryTarget> resolve() async {
    try {
      final isOnboardingCompleted = await onboardingStatusStore.isCompleted();
      if (!isOnboardingCompleted) return AppEntryTarget.onboarding;
    } catch (e) {
      // Safely default to showing onboarding on read failure.
      return AppEntryTarget.onboarding;
    }

    try {
      if (authRepository != null && await authRepository!.restoreSession() == null) return AppEntryTarget.unauthenticated;
      // Local identity remains the demo identity until profile migration.
      final identity = await identityGateway.ensureIdentity();
      final profile = await profileRepository.getProfile(identity.id);

      if (profile == null || !ProfileValidation.hasMinimumProfile(profile.displayName)) {
        return AppEntryTarget.createProfile;
      }

      return AppEntryTarget.ready;
    } catch (e) {
      // Critical failures (identity generation/storage) lead to failure state.
      return AppEntryTarget.entryFailure;
    }
  }
}
