import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitzone/app/app.dart';
import 'package:mitzone/app/startup_failure_app.dart';
import 'package:mitzone/bootstrap.dart';
import 'package:mitzone/core/config/app_config.dart';
import 'package:mitzone/core/config/app_environment.dart';
import 'package:mitzone/core/errors/app_exception.dart';

void main() {
  group('Bootstrap', () {
    test('Test 1: Unconfigured mode', () async {
      bool supabaseCalled = false;
      Widget? capturedApp;

      await bootstrap(
        configLoader: () => AppConfig.validated(env: AppEnvironment.local),
        supabaseInitializer: ({required url, required publishableKey}) async {
          supabaseCalled = true;
        },
        appRunner: (app) => capturedApp = app,
      );

      expect(supabaseCalled, isFalse);
      expect(capturedApp, isA<ProviderScope>());
      final providerScope = capturedApp as ProviderScope;
      expect(providerScope.child, isA<MitzoneApp>());
    });

    test('Test 2: Configured mode', () async {
      bool supabaseCalled = false;
      String? capturedUrl;
      String? capturedKey;
      Widget? capturedApp;

      await bootstrap(
        configLoader: () => AppConfig.validated(
          env: AppEnvironment.development,
          supabaseUrl: 'https://test.supabase.co',
          supabasePublishableKey: 'test-key',
        ),
        supabaseInitializer: ({required url, required publishableKey}) async {
          supabaseCalled = true;
          capturedUrl = url;
          capturedKey = publishableKey;
        },
        appRunner: (app) => capturedApp = app,
      );

      expect(supabaseCalled, isTrue);
      expect(capturedUrl, 'https://test.supabase.co');
      expect(capturedKey, 'test-key');
      expect(capturedApp, isA<ProviderScope>());
    });

    testWidgets('Test 3: Supabase initialization failure', (tester) async {
      Widget? capturedApp;

      await bootstrap(
        configLoader: () => AppConfig.validated(
          env: AppEnvironment.development,
          supabaseUrl: 'https://test.supabase.co',
          supabasePublishableKey: 'test-key',
        ),
        supabaseInitializer: ({required url, required publishableKey}) async {
          throw Exception('Network error');
        },
        appRunner: (app) => capturedApp = app,
      );

      expect(capturedApp, isA<StartupFailureApp>());

      await tester.pumpWidget(capturedApp!);

      expect(find.text('Startup Failed'), findsOneWidget);
      expect(find.textContaining('Initialization failure'), findsOneWidget);
      expect(find.textContaining('Network error'), findsNothing);
      expect(find.textContaining('test-key'), findsNothing);
    });

    testWidgets('Test 4: Configuration loader failure', (tester) async {
      Widget? capturedApp;

      await bootstrap(
        configLoader: () => throw const ConfigException('Invalid env'),
        appRunner: (app) => capturedApp = app,
      );

      expect(capturedApp, isA<StartupFailureApp>());

      await tester.pumpWidget(capturedApp!);
      expect(find.textContaining('Configuration failure'), findsOneWidget);
      expect(find.textContaining('Invalid env'), findsNothing);
    });

    testWidgets('Test 6: Retry behavior - callback present', (tester) async {
      bool retryCalled = false;

      final failureApp = StartupFailureApp(
        message: 'Fail',
        onRetry: () => retryCalled = true,
      );

      await tester.pumpWidget(failureApp);

      final retryButton = find.byType(FilledButton);
      expect(retryButton, findsOneWidget);

      await tester.tap(retryButton);
      expect(retryCalled, isTrue);
    });

    testWidgets('Test 6: Retry behavior - callback absent', (tester) async {
      final failureApp = const StartupFailureApp(
        message: 'Fail',
        onRetry: null,
      );

      await tester.pumpWidget(failureApp);

      expect(find.byType(FilledButton), findsNothing);
      expect(
        find.textContaining('Please check your network connection'),
        findsOneWidget,
      );
    });
  });
}
