import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitzone/app/router/app_router.dart';
import 'package:mitzone/app/router/app_routes.dart';
import 'package:mitzone/features/home/presentation/home_screen.dart';
import 'package:mitzone/features/profile/data/profile_providers.dart';
import 'package:mitzone/features/profile/domain/user_profile.dart';

void main() {
  Widget createHomeScreen({
    required AsyncValue<UserProfile?> profileState,
    String initialLocation = AppRoutes.home,
  }) {
    return ProviderScope(
      overrides: [
        currentProfileProvider.overrideWithValue(profileState),
        routerInitialLocationProvider.overrideWithValue(initialLocation),
      ],
      child: Consumer(
        builder: (context, ref, _) {
          final router = ref.watch(routerProvider);
          return MaterialApp.router(routerConfig: router);
        },
      ),
    );
  }

  Finder findHomeScrollable() {
    return find
        .descendant(
          of: find.byType(HomeScreen),
          matching: find.byWidgetPredicate(
            (widget) => widget is Scrollable && widget.axis == Axis.vertical,
          ),
        )
        .first;
  }

  Finder findHomeText(String text) {
    return find.descendant(
      of: find.byType(HomeScreen),
      matching: find.text(text),
    );
  }

  group('HomeScreen - Personalized Greeting', () {
    testWidgets('renders Hi, Hector for profile with name Hector', (
      tester,
    ) async {
      const profile = UserProfile(id: '1', displayName: 'Hector');
      await tester.pumpWidget(
        createHomeScreen(profileState: const AsyncValue.data(profile)),
      );
      await tester.pumpAndSettle();

      expect(findHomeText('Hi, Hector'), findsOneWidget);
      expect(
        findHomeText('Ready to see where real-world connections can lead?'),
        findsOneWidget,
      );
    });

    testWidgets('renders Unicode name Zoë correctly', (tester) async {
      const profile = UserProfile(id: '1', displayName: 'Zoë');
      await tester.pumpWidget(
        createHomeScreen(profileState: const AsyncValue.data(profile)),
      );
      await tester.pumpAndSettle();

      expect(findHomeText('Hi, Zoë'), findsOneWidget);
    });

    testWidgets('renders Welcome back when profile is loading', (tester) async {
      await tester.pumpWidget(
        createHomeScreen(profileState: const AsyncValue.loading()),
      );
      await tester.pump();

      expect(findHomeText('Welcome back'), findsOneWidget);
      expect(findHomeText('Events near you'), findsOneWidget);
    });

    testWidgets('renders friendly error when profile fails to load', (
      tester,
    ) async {
      await tester.pumpWidget(
        createHomeScreen(
          profileState: AsyncValue.error(Exception('Failed'), StackTrace.empty),
        ),
      );
      await tester.pumpAndSettle();

      expect(findHomeText("We couldn't load your profile."), findsOneWidget);
      expect(findHomeText('Try again'), findsOneWidget);
    });
  });

  group('HomeScreen - Router Actions', () {
    testWidgets('Home -> Explore events -> Events (index 1)', (tester) async {
      const profile = UserProfile(id: '1', displayName: 'Hector');
      await tester.pumpWidget(
        createHomeScreen(profileState: const AsyncValue.data(profile)),
      );
      await tester.pumpAndSettle();

      final scrollable = findHomeScrollable();
      final exploreBtn = findHomeText('Explore events');

      // Scroll to Matches card to find "Explore events"
      await tester.scrollUntilVisible(exploreBtn, 200, scrollable: scrollable);
      await tester.tap(exploreBtn);
      await tester.pumpAndSettle();

      expect(find.text('Discover what\'s happening.'), findsOneWidget);
      final nav = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(nav.selectedIndex, 1);
    });

    testWidgets('See all -> Events (index 1)', (tester) async {
      const profile = UserProfile(id: '1', displayName: 'Hector');
      await tester.pumpWidget(
        createHomeScreen(profileState: const AsyncValue.data(profile)),
      );
      await tester.pumpAndSettle();

      // Tap first "See all"
      await tester.tap(findHomeText('See all').first);
      await tester.pumpAndSettle();

      expect(find.text('Discover what\'s happening.'), findsOneWidget);
      final nav = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(nav.selectedIndex, 1);
    });

    testWidgets('Home -> View profile -> Profile (index 4)', (tester) async {
      const profile = UserProfile(id: '1', displayName: 'Hector');
      await tester.pumpWidget(
        createHomeScreen(profileState: const AsyncValue.data(profile)),
      );
      await tester.pumpAndSettle();

      final scrollable = findHomeScrollable();
      final viewProfileBtn = findHomeText('View profile');

      // Scroll to Profile card to find "View profile"
      await tester.scrollUntilVisible(
        viewProfileBtn,
        200,
        scrollable: scrollable,
      );
      await tester.tap(viewProfileBtn);
      await tester.pumpAndSettle();

      final nav = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(nav.selectedIndex, 4);
    });

    testWidgets('Home -> Scan QR -> SnackBar and remain on Home', (
      tester,
    ) async {
      const profile = UserProfile(id: '1', displayName: 'Hector');
      await tester.pumpWidget(
        createHomeScreen(profileState: const AsyncValue.data(profile)),
      );
      await tester.pumpAndSettle();

      final scrollable = findHomeScrollable();
      final scanQRBtn = findHomeText('Scan QR');

      await tester.scrollUntilVisible(scanQRBtn, 200, scrollable: scrollable);
      await tester.tap(scanQRBtn);
      await tester.pump(); // SnackBar appears

      expect(find.text('QR scanning is coming soon.'), findsOneWidget);
      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });

  group('HomeScreen - Viewport Coverage', () {
    final viewports = {
      '320x480': const Size(320, 480),
      '414x896': const Size(414, 896),
      '896x414': const Size(896, 414),
      '1024x768': const Size(1024, 768),
    };

    for (final entry in viewports.entries) {
      testWidgets('renders without overflow at ${entry.key}', (tester) async {
        tester.view.physicalSize = entry.value;
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          createHomeScreen(profileState: const AsyncValue.data(null)),
        );
        await tester.pumpAndSettle();

        // Scroll through the page
        final scrollable = findHomeScrollable();
        await tester.drag(scrollable, const Offset(0, -1000));
        await tester.pump();

        expect(tester.takeException(), isNull);

        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
      });
    }
  });

  group('HomeScreen - Text Scaling', () {
    testWidgets('renders without overflow at 2.0x text scale and scrolls', (
      tester,
    ) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
          child: createHomeScreen(profileState: const AsyncValue.data(null)),
        ),
      );
      await tester.pumpAndSettle();

      final scrollable = findHomeScrollable();

      // Verify key sections exist and are reachable
      final sections = [
        'Real moments.\nMeaningful connections.',
        'Events near you',
        'Matches',
        'Complete your profile',
        'How Mitzone works',
      ];

      for (final section in sections) {
        await tester.scrollUntilVisible(
          findHomeText(section).first,
          200,
          scrollable: scrollable,
        );
        expect(findHomeText(section), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });
  });
}
