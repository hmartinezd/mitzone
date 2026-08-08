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
import 'package:mitzone/features/splash/presentation/splash_screen.dart';
import 'package:mitzone/features/onboarding/data/onboarding_providers.dart';
import 'package:mitzone/features/onboarding/data/onboarding_status_store.dart';
import 'package:mitzone/features/onboarding/presentation/onboarding_screen.dart';

class FakeOnboardingStatusStore implements OnboardingStatusStore {
  bool completed = false;
  @override
  Future<bool> isCompleted() async => completed;
  @override
  Future<void> markCompleted() async => completed = true;
}

void main() {
  group('MitzoneApp Widget Tests', () {
    late FakeOnboardingStatusStore onboardingStore;

    setUp(() {
      onboardingStore = FakeOnboardingStatusStore();
    });

    testWidgets('renders SplashScreen initially', (tester) async {
      final config = AppConfig.validated(env: AppEnvironment.local);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(config),
            onboardingStatusStoreProvider.overrideWithValue(onboardingStore),
          ],
          child: const MitzoneApp(),
        ),
      );

      expect(find.byType(SplashScreen), findsOneWidget);

      // Advance time to clear splash timers
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('navigates to Onboarding if not completed', (tester) async {
      final config = AppConfig.validated(env: AppEnvironment.local);
      onboardingStore.completed = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(config),
            onboardingStatusStoreProvider.overrideWithValue(onboardingStore),
          ],
          child: const MitzoneApp(),
        ),
      );

      // Advance splash
      await tester.pump(const Duration(seconds: 5));
      await tester.pump(const Duration(milliseconds: 500)); // allow navigation

      expect(find.byType(OnboardingScreen), findsOneWidget);
    });

    testWidgets('navigates to Showcase if onboarding completed', (
      tester,
    ) async {
      final config = AppConfig.validated(env: AppEnvironment.local);
      onboardingStore.completed = true;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(config),
            onboardingStatusStoreProvider.overrideWithValue(onboardingStore),
          ],
          child: const MitzoneApp(),
        ),
      );

      // Advance splash
      await tester.pump(const Duration(seconds: 5));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(VisualSystemShowcaseScreen), findsOneWidget);
    });

    testWidgets('real unknown-route integration test returns to Splash', (
      tester,
    ) async {
      final config = AppConfig.validated(env: AppEnvironment.local);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(config),
            onboardingStatusStoreProvider.overrideWithValue(onboardingStore),
            routerProvider.overrideWith(
              (ref) =>
                  createAppRouter(initialLocation: '/unknown-route', ref: ref),
            ),
          ],
          child: const MitzoneApp(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      // Confirm friendly error screen appears
      expect(find.byType(RouteErrorScreen), findsOneWidget);

      // Tap return button
      await tester.tap(find.text('Return to Mitzone'));

      // Wait for navigation
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      // Confirm navigation to Splash
      expect(find.byType(SplashScreen), findsOneWidget);

      // Clear splash timers
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('renders correctly on small screens without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1.0;

      final config = AppConfig.validated(env: AppEnvironment.local);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(config),
            onboardingStatusStoreProvider.overrideWithValue(onboardingStore),
          ],
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
          overrides: [
            appConfigProvider.overrideWithValue(config),
            onboardingStatusStoreProvider.overrideWithValue(onboardingStore),
          ],
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
