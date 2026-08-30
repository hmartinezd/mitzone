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
import '../../features/events/presentation/event_details_screen.dart';
import '../../features/matches/presentation/matches_screen.dart';
import '../../features/chat/presentation/chat_screen.dart';
import '../../features/chat/presentation/conversation_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/profile/presentation/edit_profile_screen.dart';
import '../../features/profile/presentation/profile_details_screen.dart';
import '../../features/profile/presentation/other_user_profile_screen.dart';
import '../../features/profile/presentation/settings_screen.dart';
import '../../features/profile/presentation/settings_placeholders.dart';
import '../../features/navigation/presentation/main_navigation_shell.dart';
import '../../features/notifications/presentation/notification_center_screen.dart';
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
      GoRoute(path: '/app/notifications', builder: (context, state) => const NotificationCenterScreen()),
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
                routes: [
                  GoRoute(
                    path: ':eventId',
                    builder: (context, state) => EventDetailsScreen(
                      eventId: state.pathParameters['eventId']!,
                      origin: state.uri.queryParameters['origin'] == 'home'
                          ? EventDetailsOrigin.home
                          : EventDetailsOrigin.direct,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.matches,
                builder: (context, state) => const MatchesScreen(),
                routes: [
                  GoRoute(
                    path: 'profile/:userId/:encounterId',
                    builder: (context, state) {
                      final userId = state.pathParameters['userId'];
                      final encounterId = state.pathParameters['encounterId'];
                      if (userId == null || encounterId == null ||
                          !ref.read(mockIdentityRepositoryProvider).users.any((u) => u.id == userId)) {
                        return const RouteErrorScreen(error: null);
                      }
                      return OtherUserProfileScreen(userId: userId, encounterId: encounterId);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.chat,
                builder: (context, state) => const ChatScreen(),
                routes: [
                  GoRoute(
                    path: ':conversationId',
                    builder: (context, state) => ConversationScreen(
                      conversationId: state.pathParameters['conversationId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) => const EditProfileScreen(),
                  ),
                  GoRoute(
                    path: 'details',
                    builder: (context, state) => const ProfileDetailsScreen(),
                  ),
                  GoRoute(
                    path: 'settings',
                    builder: (context, state) => const SettingsScreen(),
                    routes: [
                      GoRoute(
                        path: 'account',
                        builder: (context, state) =>
                            const AccountSettingsScreen(),
                      ),
                      GoRoute(
                        path: 'privacy',
                        builder: (context, state) =>
                            const PrivacySettingsScreen(),
                      ),
                      GoRoute(
                        path: 'notifications',
                        builder: (context, state) =>
                            const NotificationsSettingsScreen(),
                      ),
                      GoRoute(
                        path: 'terms',
                        builder: (context, state) =>
                            const TermsSettingsScreen(),
                      ),
                      GoRoute(
                        path: 'privacy-policy',
                        builder: (context, state) =>
                            const PrivacyPolicySettingsScreen(),
                      ),
                    ],
                  ),
                ],
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
