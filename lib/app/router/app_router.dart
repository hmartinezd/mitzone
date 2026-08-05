import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_routes.dart';
import '../../features/foundation/presentation/visual_system_showcase_screen.dart';
import '../../features/foundation/presentation/route_error_screen.dart';

/// Factory function to create a [GoRouter] instance.
/// Useful for testing with different initial locations.
GoRouter createAppRouter({String initialLocation = AppRoutes.showcase}) {
  return GoRouter(
    initialLocation: initialLocation,
    errorBuilder: (context, state) => RouteErrorScreen(error: state.error),
    routes: [
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
