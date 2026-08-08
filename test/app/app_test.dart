import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitzone/app/app.dart';
import 'package:mitzone/app/router/app_router.dart';
import 'package:mitzone/app/router/app_routes.dart';
import 'package:mitzone/core/config/app_config.dart';
import 'package:mitzone/core/config/app_environment.dart';
import 'package:mitzone/core/providers/core_providers.dart';
import 'package:mitzone/features/foundation/presentation/visual_system_showcase_screen.dart';
import 'package:mitzone/features/foundation/presentation/route_error_screen.dart';
import 'package:mitzone/features/splash/presentation/splash_screen.dart';

void main() {
  group('MitzoneApp Widget Tests', () {
    testWidgets('renders SplashScreen initially', (tester) async {
      final config = AppConfig.validated(env: AppEnvironment.local);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appConfigProvider.overrideWithValue(config)],
          child: const MitzoneApp(),
        ),
      );

      expect(find.byType(SplashScreen), findsOneWidget);

      // Advance time to clear splash timers
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('navigates from Splash to Showcase after completion', (
      tester,
    ) async {
      final config = AppConfig.validated(env: AppEnvironment.local);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appConfigProvider.overrideWithValue(config)],
          child: const MitzoneApp(),
        ),
      );

      expect(find.byType(SplashScreen), findsOneWidget);

      // Advance time for splash completion
      await tester.pump(const Duration(seconds: 5));
      // Pump for navigation to take effect
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(VisualSystemShowcaseScreen), findsOneWidget);
    });

    testWidgets('can navigate directly to showcase route', (tester) async {
      final router = createAppRouter(initialLocation: AppRoutes.showcase);
      final config = AppConfig.validated(env: AppEnvironment.local);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            routerProvider.overrideWithValue(router),
            appConfigProvider.overrideWithValue(config),
          ],
          child: const MitzoneApp(),
        ),
      );

      expect(find.byType(VisualSystemShowcaseScreen), findsOneWidget);
      router.dispose();
    });

    testWidgets('real unknown-route integration test', (tester) async {
      final router = createAppRouter(initialLocation: '/unknown-route');
      final config = AppConfig.validated(env: AppEnvironment.local);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            routerProvider.overrideWithValue(router),
            appConfigProvider.overrideWithValue(config),
          ],
          child: const MitzoneApp(),
        ),
      );

      // Wait for router to settle
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      // Confirm friendly error screen appears
      expect(find.byType(RouteErrorScreen), findsOneWidget);
      expect(find.text('Page Not Found'), findsOneWidget);

      // Tap return button
      final returnButton = find.text('Return to Mitzone');
      expect(returnButton, findsOneWidget);
      await tester.tap(returnButton);

      // Wait for navigation
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      // Confirm navigation to Splash
      expect(find.byType(SplashScreen), findsOneWidget);

      // Clear splash timers
      await tester.pump(const Duration(seconds: 5));

      // Dispose the test router
      router.dispose();
    });

    testWidgets('renders correctly on small screens without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1.0;

      final config = AppConfig.validated(env: AppEnvironment.local);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appConfigProvider.overrideWithValue(config)],
          child: const MitzoneApp(),
        ),
      );

      expect(tester.takeException(), isNull);

      // Clear splash timers
      await tester.pump(const Duration(seconds: 5));

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });

    testWidgets('supports large text scaling', (tester) async {
      final config = AppConfig.validated(env: AppEnvironment.local);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appConfigProvider.overrideWithValue(config)],
          child: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
            child: const MitzoneApp(),
          ),
        ),
      );

      expect(tester.takeException(), isNull);

      // Clear splash timers
      await tester.pump(const Duration(seconds: 5));
    });
  });
}
