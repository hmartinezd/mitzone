import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitzone/features/home/presentation/home_screen.dart';
import 'package:mitzone/features/profile/data/profile_providers.dart';
import 'package:mitzone/features/profile/domain/user_profile.dart';

void main() {
  Widget createHomeScreen({required AsyncValue<UserProfile?> profileState}) {
    return ProviderScope(
      overrides: [currentProfileProvider.overrideWithValue(profileState)],
      child: const MaterialApp(home: HomeScreen()),
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
      await tester.pump();

      expect(find.text('Hi, Hector'), findsOneWidget);
      expect(
        find.text('Ready to see where real-world connections can lead?'),
        findsOneWidget,
      );
    });

    testWidgets('renders Unicode name Zoë correctly', (tester) async {
      const profile = UserProfile(id: '1', displayName: 'Zoë');
      await tester.pumpWidget(
        createHomeScreen(profileState: const AsyncValue.data(profile)),
      );
      await tester.pump();

      expect(find.text('Hi, Zoë'), findsOneWidget);
    });

    testWidgets('renders Welcome back when profile is loading', (tester) async {
      await tester.pumpWidget(
        createHomeScreen(profileState: const AsyncValue.loading()),
      );

      expect(find.text('Welcome back'), findsOneWidget);
      // Other sections should still be there
      expect(find.text('Events near you'), findsOneWidget);
    });

    testWidgets('renders friendly error when profile fails to load', (
      tester,
    ) async {
      await tester.pumpWidget(
        createHomeScreen(
          profileState: AsyncValue.error(Exception('Failed'), StackTrace.empty),
        ),
      );
      await tester.pump();
      await tester.pump(Duration.zero);
      await tester.pump();

      expect(find.text("We couldn't load your profile."), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('renders Finish your profile when profile is missing', (
      tester,
    ) async {
      await tester.pumpWidget(
        createHomeScreen(profileState: const AsyncValue.data(null)),
      );
      await tester.pump();

      expect(
        find.text('Finish your profile to get the most out of Mitzone.'),
        findsOneWidget,
      );
    });
  });

  group('HomeScreen - Required Sections', () {
    testWidgets('renders all required dashboard sections', (tester) async {
      await tester.pumpWidget(
        createHomeScreen(profileState: const AsyncValue.data(null)),
      );
      await tester.pump();

      expect(
        find.text('Real moments.\nMeaningful connections.'),
        findsOneWidget,
      );
      expect(find.text('Events near you'), findsOneWidget);
      expect(find.text('Popular events'), findsOneWidget);
      expect(find.text('Upcoming activities'), findsOneWidget);
      expect(find.text('Matches'), findsOneWidget);
      expect(find.text('No matches yet'), findsOneWidget);
      expect(find.text('Complete your profile'), findsOneWidget);
      expect(find.text('How Mitzone works'), findsOneWidget);
    });
  });

  group('HomeScreen - Demo Events', () {
    testWidgets('renders demo events in sections', (tester) async {
      await tester.pumpWidget(
        createHomeScreen(profileState: const AsyncValue.data(null)),
      );
      await tester.pump();

      // Check for Tech Mixer (which is in nearby and upcoming)
      expect(find.text('Tech Mixer 2026'), findsNWidgets(2));
      expect(find.text('DEMO'), findsOneWidget); // Nearby badge
    });
  });

  group('HomeScreen - Accessibility and Responsiveness', () {
    testWidgets('renders without overflow at small size (320x480)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        createHomeScreen(profileState: const AsyncValue.data(null)),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });

    testWidgets('renders without overflow at 2.0x text scale', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
          child: createHomeScreen(profileState: const AsyncValue.data(null)),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });
}
