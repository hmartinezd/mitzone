import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/identity/identity_providers.dart';
import '../../features/foundation/presentation/entry_failure_screen.dart';
import '../../features/foundation/presentation/route_error_screen.dart';
import '../../features/foundation/presentation/visual_system_showcase_screen.dart';
import '../../features/onboarding/data/onboarding_providers.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/profile/data/profile_providers.dart';
import '../../features/profile/presentation/create_minimum_profile_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/events/presentation/events_screen.dart';
import '../../features/matches/presentation/matches_screen.dart';
import '../../features/chat/presentation/chat_screen.dart';
import '../../features/profile/presentation/profile_preview_screen.dart';
import '../../features/navigation/presentation/main_navigation_shell.dart';
import 'app_entry_resolver.dart';
import 'app_routes.dart';
import 'app_entry_coordinator.dart';

/// Global key for the root navigator.
final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

/// Factory function to create a [GoRouter] instance.
GoRouter createAppRouter({
  String initialLocation = AppRoutes.splash,
  required Ref ref,
}) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: initialLocation,
    errorBuilder: (context, state) => RouteErrorScreen(error: state.error),
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) {
          return SplashScreen(
            onCompleted: () async {
              final resolver = AppEntryResolver(
                onboardingStatusStore: ref.read(onboardingStatusStoreProvider),
                identityGateway: ref.read(identityGatewayProvider),
                profileRepository: ref.read(profileRepositoryProvider),
              );

              final target = await resolver.resolve();

              if (!context.mounted) return;

              final location = AppEntryCoordinator.locationForTarget(target);
              context.go(location);
            },
          );
        },
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.createProfile,
        builder: (context, state) => const CreateMinimumProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.entryFailure,
        builder: (context, state) => const EntryFailureScreen(),
      ),
      GoRoute(
        path: AppRoutes.showcase,
        builder: (context, state) => const VisualSystemShowcaseScreen(),
      ),

      // Main Navigation Shell
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainNavigationShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.events,
                builder: (context, state) => const EventsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.matches,
                builder: (context, state) => const MatchesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.chat,
                builder: (context, state) => const ChatScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const ProfilePreviewScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

/// Provider for the initial location of the router.
/// This can be overridden in tests to start at a specific route.
final routerInitialLocationProvider = Provider<String>(
  (ref) => AppRoutes.splash,
);

/// Provider for the application router.
final routerProvider = Provider<GoRouter>((ref) {
  final initialLocation = ref.watch(routerInitialLocationProvider);
  final router = createAppRouter(initialLocation: initialLocation, ref: ref);
  ref.onDispose(router.dispose);
  return router;
});
