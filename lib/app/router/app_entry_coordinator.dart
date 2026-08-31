import 'app_entry_resolver.dart';
import 'app_routes.dart';

/// Centralized coordinator for mapping application entry targets to routes.
class AppEntryCoordinator {
  /// Returns the location corresponding to the given [target].
  static String locationForTarget(AppEntryTarget target) {
    switch (target) {
      case AppEntryTarget.onboarding:
        return AppRoutes.onboarding;
      case AppEntryTarget.createProfile:
        return AppRoutes.createProfile;
      case AppEntryTarget.ready:
        // Ready destination for Phase 6 is Main Navigation Home.
        return AppRoutes.home;
      case AppEntryTarget.entryFailure:
        return AppRoutes.entryFailure;
      case AppEntryTarget.unauthenticated:
        return AppRoutes.login;
    }
  }
}
