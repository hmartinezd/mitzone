import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mitzone/app/router/app_routes.dart';
import 'package:mitzone/core/auth/auth_providers.dart';
import 'package:mitzone/features/encounters/data/foreground_location_sources.dart';
import 'package:mitzone/features/events/data/event_providers.dart';
import 'package:mitzone/features/events/domain/event.dart';
import 'package:mitzone/features/events/presentation/events_screen.dart';
import 'package:mitzone/features/home/presentation/widgets/shared_moments_hero.dart';

const event = Event(
  id: '1',
  title: 'Music in the park',
  venue: 'Public park',
  timeLabel: 'Tomorrow',
  category: 'Music and community activities',
  description: 'A concert',
);

void main() {
  Future<void> show(
    WidgetTester tester, {
    AsyncValue<List<Event>> state = const AsyncData([]),
    double scale = 1,
    Future<bool> Function()? appSettings,
    Future<bool> Function()? locationSettings,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          productionModeProvider.overrideWithValue(true),
          nearbyEventsProvider.overrideWithValue(state),
          joinedEventIdsProvider.overrideWithValue(const AsyncData(<String>{})),
          openActivityAppSettingsProvider.overrideWithValue(
            appSettings ?? () async => false,
          ),
          openActivityLocationSettingsProvider.overrideWithValue(
            locationSettings ?? () async => false,
          ),
        ],
        child: MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: const Scaffold(body: EventsScreen()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('unfiltered empty discovery offers refresh, not filter blame', (
    tester,
  ) async {
    await show(tester);
    expect(
      find.text('No nearby activities are available right now.'),
      findsOneWidget,
    );
    expect(find.text('Refresh'), findsOneWidget);
    expect(find.text('Clear filters'), findsNothing);
    expect(find.byTooltip('Back'), findsOneWidget);
  });

  testWidgets('filtered empty discovery can clear search', (tester) async {
    await show(tester, state: const AsyncData([event]));
    await tester.enterText(find.byType(TextField), 'No matching activity');
    await tester.pumpAndSettle();
    expect(find.text('No activities match your filters.'), findsOneWidget);
    await tester.ensureVisible(find.text('Clear filters'));
    await tester.tap(find.text('Clear filters'));
    await tester.pumpAndSettle();
    expect(find.text(event.title), findsOneWidget);
  });

  testWidgets('permanent denial opens app settings only after explicit tap', (
    tester,
  ) async {
    var calls = 0;
    await show(
      tester,
      state: AsyncError(
        const ForegroundLocationException(
          ForegroundLocationFailure.permissionPermanentlyDenied,
        ),
        StackTrace.empty,
      ),
      appSettings: () async {
        calls++;
        return false;
      },
    );
    expect(calls, 0);
    await tester.tap(find.text('Open app settings'));
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(
      find.text(
        'Could not open settings. Open your device settings to review location access.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('disabled location services use distinct settings destination', (
    tester,
  ) async {
    var locationCalls = 0;
    var appCalls = 0;
    await show(
      tester,
      state: AsyncError(
        const ForegroundLocationException(
          ForegroundLocationFailure.servicesDisabled,
        ),
        StackTrace.empty,
      ),
      locationSettings: () async {
        locationCalls++;
        return true;
      },
      appSettings: () async {
        appCalls++;
        return true;
      },
    );
    await tester.tap(find.text('Open location settings'));
    await tester.pumpAndSettle();
    expect(locationCalls, 1);
    expect(appCalls, 0);
    expect(
      find.text('Return here and try again after updating location access.'),
      findsOneWidget,
    );
  });

  testWidgets('large text keeps category and search labels without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(411, 914);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await show(tester, state: const AsyncData([event]), scale: 2);
    expect(find.text('Category'), findsOneWidget);
    expect(find.text('Search'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('activities back returns to its existing Explore context', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: AppRoutes.explore,
      routes: [
        GoRoute(
          path: AppRoutes.explore,
          builder: (context, _) => Scaffold(
            body: TextButton(
              onPressed: () => context.push(AppRoutes.exploreActivities),
              child: const Text('Open activities'),
            ),
          ),
          routes: [
            GoRoute(
              path: 'activities',
              builder: (_, _) => const Scaffold(body: EventsScreen()),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          productionModeProvider.overrideWithValue(true),
          nearbyEventsProvider.overrideWithValue(const AsyncData(<Event>[])),
          joinedEventIdsProvider.overrideWithValue(const AsyncData(<String>{})),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.tap(find.text('Open activities'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Open activities'), findsOneWidget);
  });

  testWidgets('Home reminder is compact and respects large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(411, 914);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final scale in [1.0, 2.0]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(scale)),
              child: const Padding(
                padding: EdgeInsets.all(24),
                child: SharedMomentsHero(),
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(
        find.descendant(
          of: find.byType(SharedMomentsHero),
          matching: find.byType(Stack),
        ),
        findsNothing,
      );
      if (scale == 1) {
        expect(
          tester.getSize(find.byType(SharedMomentsHero)).height,
          lessThan(260),
        );
      }
      expect(
        MediaQuery.textScalerOf(
          tester.element(find.text('Real moments, intentional connection.')),
        ).scale(10),
        10 * scale,
      );
    }
  });
}
