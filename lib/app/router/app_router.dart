import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/foundation/presentation/route_error_screen.dart';
import '../../features/foundation/presentation/visual_system_showcase_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import 'app_routes.dart';

/// Factory function to create a [GoRouter] instance.
/// Useful for testing with different initial locations.
GoRouter createAppRouter({String initialLocation = AppRoutes.splash}) {
  return GoRouter(
    initialLocation: initialLocation,
    errorBuilder: (context, state) => RouteErrorScreen(error: state.error),
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) {
          return SplashScreen(
            onCompleted: () {
              // TEMPORARY: Navigation to showcase until onboarding/auth is implemented.
              // Future application-entry policy:
              // active session + complete minimum profile -> Home
              // active session + incomplete minimum profile -> Create Profile
              // no session + onboarding completed -> Login
              // first use -> Onboarding
              context.go(AppRoutes.showcase);
            },
          );
        },
      ),
      GoRoute(
        path: AppRoutes.showcase,
        builder: (context, state) => const VisualSystemShowcaseScreen(),
      ),
    ],
  );
}

/// Provider for the application router.
final routerProvider = Provider<GoRouter>((ref) {
  final router = createAppRouter();
  ref.onDispose(router.dispose);
  return router;
});
