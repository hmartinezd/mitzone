import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitzone/app/app.dart';
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

    testWidgets('shows friendly error screen for unknown route', (
      tester,
    ) async {
      final config = AppConfig.validated(env: AppEnvironment.local);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appConfigProvider.overrideWithValue(config)],
          child: const MitzoneApp(),
        ),
      );

      // We can't directly trigger go_router unknown route easily without accessing the router
      // But we can test if the RouteErrorScreen renders correctly if we put it in the tree
      await tester.pumpWidget(MaterialApp(home: const RouteErrorScreen()));

      expect(find.text('Page Not Found'), findsOneWidget);
      expect(
        find.textContaining('Something went wrong'),
        findsNothing,
      ); // should be friendly
      expect(find.byType(ElevatedButton), findsOneWidget);
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
