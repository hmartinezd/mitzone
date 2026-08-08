import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitzone/app/theme/app_theme.dart';
import 'package:mitzone/features/onboarding/data/onboarding_providers.dart';
import 'package:mitzone/features/onboarding/data/onboarding_status_store.dart';
import 'package:mitzone/features/onboarding/presentation/onboarding_screen.dart';
import 'package:mitzone/shared/widgets/mitzone_button.dart';

class FakeOnboardingStatusStore implements OnboardingStatusStore {
  bool completed = false;
  int markCompletedCount = 0;
  bool shouldThrow = false;

  @override
  Future<bool> isCompleted() async => completed;

  @override
  Future<void> markCompleted() async {
    if (shouldThrow) throw Exception('Storage failure');
    markCompletedCount++;
    completed = true;
  }
}

void main() {
  group('OnboardingScreen', () {
    late FakeOnboardingStatusStore store;

    setUp(() {
      store = FakeOnboardingStatusStore();
    });

    Widget createWidget() {
      return ProviderScope(
        overrides: [onboardingStatusStoreProvider.overrideWithValue(store)],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const OnboardingScreen(),
        ),
      );
    }

    testWidgets('renders first page initially with Next and Skip', (
      tester,
    ) async {
      await tester.pumpWidget(createWidget());

      expect(
        find.text('The best connections begin in the real world.'),
        findsOneWidget,
      );
      expect(find.text('Skip'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
    });

    testWidgets('navigates through pages using Next button', (tester) async {
      await tester.pumpWidget(createWidget());

      // Page 1 -> 2
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Share experiences.'), findsOneWidget);

      // Page 2 -> 3
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Turn encounters into opportunities.'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);

      // Skip should be effectively hidden (opacity 0)
      final skipFinder = find.text('Skip');
      final skipWidget = tester.widget<Opacity>(
        find.ancestor(of: skipFinder, matching: find.byType(Opacity)),
      );
      expect(skipWidget.opacity, 0.0);
    });

    testWidgets('can swipe between pages', (tester) async {
      await tester.pumpWidget(createWidget());

      // Swipe Page 1 -> 2
      await tester.drag(find.byType(PageView), const Offset(-600, 0));
      await tester.pumpAndSettle();
      expect(find.text('Share experiences.'), findsOneWidget);

      // Swipe Page 2 -> 1
      await tester.drag(find.byType(PageView), const Offset(600, 0));
      await tester.pumpAndSettle();
      expect(
        find.text('The best connections begin in the real world.'),
        findsOneWidget,
      );
    });

    testWidgets('Skip persists completion and tries to navigate', (
      tester,
    ) async {
      await tester.pumpWidget(createWidget());

      await tester.tap(find.text('Skip'));
      await tester.pump(); // Start async operation

      expect(store.markCompletedCount, 1);
    });

    testWidgets('Get Started persists completion', (tester) async {
      await tester.pumpWidget(createWidget());

      // Move to last page
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Get Started'));
      await tester.pump();

      expect(store.markCompletedCount, 1);
    });

    testWidgets('shows error message on persistence failure', (tester) async {
      store.shouldThrow = true;
      await tester.pumpWidget(createWidget());

      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      expect(
        find.text("We couldn't save your progress. Please try again."),
        findsOneWidget,
      );
      // Button should be enabled again
      expect(
        tester.widget<MitzoneButton>(find.byType(MitzoneButton)).onPressed,
        isNotNull,
      );
    });

    testWidgets('handles small viewport without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidget());
      expect(tester.takeException(), isNull);
    });

    testWidgets('handles 2.0 text scaling without overflow', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [onboardingStatusStoreProvider.overrideWithValue(store)],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(2.0)),
              child: OnboardingScreen(),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('respects reduced motion when using Next button', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [onboardingStatusStoreProvider.overrideWithValue(store)],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const MediaQuery(
              data: MediaQueryData(disableAnimations: true),
              child: OnboardingScreen(),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Next'));
      // With reduced motion (jumpToPage), it should be immediate
      await tester.pump();
      expect(find.text('Share experiences.'), findsOneWidget);
    });
  });
}
