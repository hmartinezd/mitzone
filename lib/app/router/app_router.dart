import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/foundation/presentation/route_error_screen.dart';
import '../../features/foundation/presentation/visual_system_showcase_screen.dart';
import '../../features/onboarding/data/onboarding_providers.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import 'app_entry_resolver.dart';
import 'app_routes.dart';

/// Factory function to create a [GoRouter] instance.
/// Useful for testing with different initial locations.
GoRouter createAppRouter({
  String initialLocation = AppRoutes.splash,
  required Ref ref,
}) {
  return GoRouter(
    initialLocation: initialLocation,
    errorBuilder: (context, state) => RouteErrorScreen(error: state.error),
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) {
          return SplashScreen(
            onCompleted: () async {
              final store = ref.read(onboardingStatusStoreProvider);
              final resolver = AppEntryResolver(store);
              final target = await resolver.resolve();

              if (!context.mounted) return;

              switch (target) {
                case AppEntryTarget.onboarding:
                  context.go(AppRoutes.onboarding);
                case AppEntryTarget.postOnboarding:
                  // TEMPORARY: Showcase until auth is implemented.
                  context.go(AppRoutes.showcase);
              }
            },
          );
        },
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
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
  final router = createAppRouter(ref: ref);
  ref.onDispose(router.dispose);
  return router;
});
