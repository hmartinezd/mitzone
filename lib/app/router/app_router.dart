import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_routes.dart';
import '../../features/foundation/presentation/foundation_screen.dart';
import '../../features/foundation/presentation/route_error_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.foundation,
    errorBuilder: (context, state) => RouteErrorScreen(error: state.error),
    routes: [
      GoRoute(
        path: AppRoutes.foundation,
        builder: (context, state) => const FoundationScreen(),
      ),
    ],
  );
});
