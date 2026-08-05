import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitzone/app/app.dart';
import 'package:mitzone/app/router/app_router.dart';
import 'package:mitzone/core/config/app_config.dart';
import 'package:mitzone/core/config/app_environment.dart';
import 'package:mitzone/core/providers/core_providers.dart';
import 'package:mitzone/features/foundation/presentation/visual_system_showcase_screen.dart';
import 'package:mitzone/features/foundation/presentation/route_error_screen.dart';

void main() {
  group('MitzoneApp Widget Tests', () {
    testWidgets('renders VisualSystemShowcaseScreen initially', (tester) async {
      final config = AppConfig.validated(env: AppEnvironment.local);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appConfigProvider.overrideWithValue(config)],
          child: const MitzoneApp(),
        ),
      );

      expect(find.byType(VisualSystemShowcaseScreen), findsOneWidget);
      expect(find.text('Visual System Showcase'), findsOneWidget);
      expect(find.text('Mitzone'), findsWidgets);
    });

    testWidgets('shows unconfigured Supabase state in showcase', (tester) async {
      final config = AppConfig.validated(env: AppEnvironment.local);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appConfigProvider.overrideWithValue(config)],
          child: const MitzoneApp(),
        ),
      );

      expect(find.text('Unconfigured'), findsOneWidget);
    });

    testWidgets('shows configured Supabase state in showcase', (tester) async {
      final config = AppConfig.validated(
        env: AppEnvironment.development,
        supabaseUrl: 'https://example.supabase.co',
        supabasePublishableKey: 'key',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appConfigProvider.overrideWithValue(config)],
          child: const MitzoneApp(),
        ),
      );

      expect(find.text('Configured'), findsOneWidget);
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

      // Wait for router to settle - using pump with duration to avoid infinite settle
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      // Confirm friendly error screen appears
      expect(find.byType(RouteErrorScreen), findsOneWidget);
      expect(find.text('Page Not Found'), findsOneWidget);

      // Tap return button
      final returnButton = find.text('Back to Showcase');
      expect(returnButton, findsOneWidget);
      await tester.tap(returnButton);

      // Wait for navigation
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      // Confirm navigation to Showcase
      expect(find.byType(VisualSystemShowcaseScreen), findsOneWidget);

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
    });
  });
}
