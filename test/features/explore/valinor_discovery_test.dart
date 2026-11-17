import 'package:mitzone/features/home/presentation/widgets/discovery_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitzone/app/theme/app_theme.dart';
import 'package:mitzone/core/config/app_config.dart';
import 'package:mitzone/core/config/app_environment.dart';
import 'package:mitzone/core/providers/core_providers.dart';
import 'package:mitzone/features/discovery/data/discovery_providers.dart';
import 'package:mitzone/features/discovery/domain/discovery_item.dart';
import 'package:mitzone/features/events/data/event_providers.dart';
import 'package:mitzone/features/events/domain/event.dart';
import 'package:mitzone/features/explore/presentation/explore_screen.dart';
import 'package:mitzone/features/home/presentation/home_screen.dart';

// Offline fixtures only; these never enter a production repository or fallback.
const place = DiscoveryItem(
  id: 'fixture-place',
  source: 'google-places',
  type: DiscoveryItemType.place,
  title: 'Fixture Coffee House',
  category: ['food'],
  context: 'Fixture Street',
  distanceKm: 1.2,
);
const event = Event(
  id: 'fixture-event',
  title: 'Fixture Music Evening',
  venue: 'Fixture Hall',
  timeLabel: 'Tomorrow, 7 PM',
  category: 'Music',
  description:
      'This long fixture description should not be browsing-card copy.',
  source: 'ticketmaster',
  imageKey: 'https://example.invalid/fixture-photo.jpg',
  imageAttribution: 'Fixture Photographer',
);

Widget app({double scale = 1}) => ProviderScope(
  overrides: [
    appConfigProvider.overrideWithValue(
      AppConfig.validated(env: AppEnvironment.local),
    ),
    homeDiscoveryInterestsProvider.overrideWithValue(const <String>{}),
    nearbyDiscoveryProvider(
      const <String>{},
    ).overrideWithValue(const AsyncData([place])),
    nearbyEventsProvider.overrideWithValue(const AsyncData([event])),
  ],
  child: MaterialApp(
    theme: AppTheme.lightTheme,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
    ),
    home: const Scaffold(body: ExploreScreen()),
  ),
);

void main() {
  testWidgets(
    'provider credit is not duplicated when photo credit is identical',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: DiscoverySection(
                vertical: true,
                items: const [
                  DiscoveryItem(
                    id: 'fixture-credit',
                    source: 'ticketmaster',
                    type: DiscoveryItemType.activity,
                    title: 'Fixture event',
                    category: [],
                    imageAttribution: 'Ticketmaster',
                  ),
                ],
                onSeeAll: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Ticketmaster'), findsOneWidget);
    },
  );

  testWidgets('search and type filters operate on loaded provider results', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(find.text(place.title), findsOneWidget);
    expect(find.text(event.title), findsOneWidget);
    expect(find.text('Private & Verified'), findsNothing);
    expect(find.text(event.description), findsNothing);
    await tester.enterText(find.byType(TextField), 'coffee');
    await tester.pumpAndSettle();
    expect(find.text(place.title), findsOneWidget);
    expect(find.text(event.title), findsNothing);
    await tester.enterText(find.byType(TextField), '');
    await tester.tap(find.text('Activities'));
    await tester.pumpAndSettle();
    expect(find.text(place.title), findsNothing);
    expect(find.text(event.title), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'not a match');
    await tester.pumpAndSettle();
    expect(find.text('No nearby matches.'), findsOneWidget);
    expect(find.text(event.title), findsNothing);
  });

  testWidgets(
    'cards share image geometry and retain honest source/photo states',
    (tester) async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      final frames = tester.widgetList<AspectRatio>(find.byType(AspectRatio));
      expect(frames.length, 2);
      expect(frames.every((frame) => frame.aspectRatio == 16 / 9), isTrue);
      expect(find.text('Photo unavailable'), findsWidgets);
      expect(find.text('Google Maps'), findsOneWidget);
      expect(find.text('Ticketmaster'), findsOneWidget);
      expect(find.text('Fixture Photographer'), findsOneWidget);
      expect(find.textContaining('1.2 km away'), findsOneWidget);
      expect(find.text(event.timeLabel), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('compact discovery remains scrollable at twice text size', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(app(scale: 2));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.drag(
      find.byKey(const PageStorageKey('explore-discovery-scroll')),
      const Offset(0, -800),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  test('Valinor theme uses approved palette and licensed type families', () {
    final theme = AppTheme.lightTheme;
    expect(theme.scaffoldBackgroundColor, const Color(0xfffaf9f6));
    expect(theme.colorScheme.primaryContainer, const Color(0xffd4af37));
    expect(theme.colorScheme.secondary, const Color(0xff376284));
    expect(theme.textTheme.headlineLarge!.fontFamily, 'EBGaramond');
    expect(theme.textTheme.bodyMedium!.fontFamily, 'PlusJakartaSans');
  });
}
