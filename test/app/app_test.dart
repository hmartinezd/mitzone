import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitzone/app/app.dart';
import 'package:mitzone/app/router/app_router.dart';
import 'package:mitzone/core/config/app_config.dart';
import 'package:mitzone/core/config/app_environment.dart';
import 'package:mitzone/core/providers/core_providers.dart';
import 'package:mitzone/features/foundation/presentation/foundation_screen.dart';
import 'package:mitzone/features/foundation/presentation/route_error_screen.dart';

void main() {
  group('MitzoneApp Widget Tests', () {
    testWidgets('renders FoundationScreen initially', (tester) async {
      final config = AppConfig.validated(env: AppEnvironment.local);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appConfigProvider.overrideWithValue(config)],
          child: const MitzoneApp(),
        ),
      );

      expect(find.byType(FoundationScreen), findsOneWidget);
      expect(find.text('Mitzone'), findsOneWidget);
      expect(
        find.text('The best connections begin in the real world.'),
        findsOneWidget,
      );
    });

    testWidgets('shows unconfigured Supabase state', (tester) async {
      final config = AppConfig.validated(env: AppEnvironment.local);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appConfigProvider.overrideWithValue(config)],
          child: const MitzoneApp(),
        ),
      );

      expect(find.text('Not Configured'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);
    });

    testWidgets('shows configured Supabase state', (tester) async {
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
      expect(find.byIcon(Icons.cloud_done_outlined), findsOneWidget);
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
      await tester.pumpAndSettle();

      // Confirm friendly error screen appears
      expect(find.byType(RouteErrorScreen), findsOneWidget);
      expect(find.text('Page Not Found'), findsOneWidget);

      // Confirm no raw implementation details (like Exception text)
      expect(find.textContaining('Exception:'), findsNothing);

      // Tap return button
      final returnButton = find.byType(FilledButton);
      expect(returnButton, findsOneWidget);
      await tester.tap(returnButton);

      // Wait for navigation
      await tester.pumpAndSettle();

      // Confirm navigation to Foundation Screen
      expect(find.byType(FoundationScreen), findsOneWidget);

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
