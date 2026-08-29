import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitzone/app/router/app_router.dart';
import 'package:mitzone/app/router/app_routes.dart';
import 'package:mitzone/core/identity/mock_identity_repository.dart';
import 'package:mitzone/features/chat/data/chat_providers.dart';
import 'package:mitzone/features/chat/domain/chat_models.dart';
import 'package:mitzone/features/chat/presentation/conversation_screen.dart';
import 'package:mitzone/features/connections/data/connection_providers.dart';
import 'package:mitzone/features/connections/domain/connection.dart';
import 'package:mitzone/features/connections/domain/connection_request.dart';
import 'package:mitzone/features/encounters/data/encounter_providers.dart';
import 'package:mitzone/features/encounters/domain/encounter.dart';
import 'package:mitzone/features/events/data/event_providers.dart';
import 'package:mitzone/features/home/presentation/home_screen.dart';
import 'package:mitzone/features/profile/data/profile_providers.dart';
import 'package:mitzone/features/profile/domain/user_profile.dart';

void main() {
  Widget createHomeScreen({
    required AsyncValue<UserProfile?> profileState,
    AsyncValue<Set<String>> joinedEventIdsState = const AsyncValue.data(
      <String>{},
    ),
    AsyncValue<List<Encounter>> encounterState = const AsyncValue.data([]),
    AsyncValue<List<ConnectionRequest>> requestState = const AsyncValue.data(
      [],
    ),
    AsyncValue<List<Connection>> connectionState = const AsyncValue.data([]),
    AsyncValue<List<Conversation>> conversationState = const AsyncValue.data(
      [],
    ),
    String initialLocation = AppRoutes.home,
  }) {
    return ProviderScope(
      overrides: [
        currentProfileProvider.overrideWithValue(profileState),
        joinedEventIdsProvider.overrideWithValue(joinedEventIdsState),
        encountersForCurrentUserProvider.overrideWithValue(encounterState),
        incomingConnectionRequestsProvider.overrideWithValue(requestState),
        connectionsProvider.overrideWithValue(connectionState),
        chatConversationsProvider.overrideWithValue(conversationState),
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

  group('HomeScreen - Upcoming activities', () {
    testWidgets('shows the empty participation state', (tester) async {
      await tester.pumpWidget(
        createHomeScreen(profileState: const AsyncValue.data(null)),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        findHomeText('No upcoming activities yet.'),
        200,
        scrollable: findHomeScrollable(),
      );
      expect(findHomeText('Find an event'), findsOneWidget);
    });

    testWidgets('shows joined catalog events', (tester) async {
      await tester.pumpWidget(
        createHomeScreen(
          profileState: const AsyncValue.data(null),
          joinedEventIdsState: const AsyncValue.data({'tech-mixer-2026'}),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        findHomeText('Upcoming activities'),
        200,
        scrollable: findHomeScrollable(),
      );
      final upcoming = find
          .ancestor(
            of: findHomeText('Upcoming activities'),
            matching: find.byType(Column),
          )
          .first;
      expect(
        find.descendant(of: upcoming, matching: find.text('Tech Mixer 2026')),
        findsOneWidget,
      );
    });

    testWidgets('shows a distinct participation error state', (tester) async {
      await tester.pumpWidget(
        createHomeScreen(
          profileState: const AsyncValue.data(null),
          joinedEventIdsState: AsyncValue.error(
            Exception('failed'),
            StackTrace.empty,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        findHomeText("We couldn't load your upcoming activities."),
        200,
        scrollable: findHomeScrollable(),
      );
      expect(findHomeText('Try again'), findsOneWidget);
      expect(findHomeText('No upcoming activities yet.'), findsNothing);
    });

    testWidgets('participation retry invalidates and reaches success', (
      tester,
    ) async {
      var attempts = 0;
      var allowSuccess = false;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentProfileProvider.overrideWithValue(
              const AsyncValue.data(null),
            ),
            joinedEventIdsProvider.overrideWith((ref) async {
              attempts += 1;
              if (!allowSuccess) throw Exception('failed');
              return <String>{};
            }),
            routerInitialLocationProvider.overrideWithValue(AppRoutes.home),
          ],
          child: Consumer(
            builder: (context, ref, _) =>
                MaterialApp.router(routerConfig: ref.watch(routerProvider)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        findHomeText("We couldn't load your upcoming activities."),
        200,
        scrollable: findHomeScrollable(),
      );
      allowSuccess = true;
      final attemptsBeforeRetry = attempts;
      await tester.tap(findHomeText('Try again'));
      await tester.pumpAndSettle();
      expect(attempts, greaterThan(attemptsBeforeRetry));
      expect(findHomeText('No upcoming activities yet.'), findsOneWidget);
    });

    testWidgets('unknown joined IDs safely show the empty state', (
      tester,
    ) async {
      await tester.pumpWidget(
        createHomeScreen(
          profileState: const AsyncValue.data(null),
          joinedEventIdsState: const AsyncValue.data({'removed-event'}),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        findHomeText('No upcoming activities yet.'),
        200,
        scrollable: findHomeScrollable(),
      );
      expect(findHomeText('removed-event'), findsNothing);
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
  });

  group('HomeScreen - Social summary', () {
    final observedAt = DateTime.utc(2027, 3, 4, 12, 45);
    final encounter = Encounter(
      id: 'encounter',
      currentUserId: MockUsers.joseId,
      otherUserId: MockUsers.sofiaId,
      eventId: 'urban-art-opening',
      overlapStart: observedAt.subtract(const Duration(minutes: 45)),
      overlapEnd: observedAt,
    );
    final connection = Connection(
      id: 'connection',
      userAId: MockUsers.joseId,
      userBId: MockUsers.sofiaId,
      encounterId: encounter.id,
      contextId: 'urban-art-opening:${MockUsers.joseId}:${MockUsers.sofiaId}',
      connectedAt: observedAt,
    );

    testWidgets('empty social state explains check-in and offers Events', (
      tester,
    ) async {
      await tester.pumpWidget(
        createHomeScreen(profileState: const AsyncValue.data(null)),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        findHomeText('No shared moments yet'),
        200,
        scrollable: findHomeScrollable(),
      );

      expect(
        findHomeText(
          'Check in at an event to discover people you crossed paths with.',
        ),
        findsOneWidget,
      );
      expect(findHomeText('Explore events'), findsOneWidget);
    });

    testWidgets('encounters resolve person and event without obsolete copy', (
      tester,
    ) async {
      await tester.pumpWidget(
        createHomeScreen(
          profileState: const AsyncValue.data(null),
          encounterState: AsyncValue.data([encounter]),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        findHomeText('People you crossed paths with'),
        200,
        scrollable: findHomeScrollable(),
      );

      expect(findHomeText('Sofia'), findsOneWidget);
      expect(findHomeText('Urban Art Gallery Opening'), findsWidgets);
      expect(findHomeText('No matches yet'), findsNothing);
      expect(findHomeText('1 person from your recent moments'), findsOneWidget);
    });

    testWidgets('incoming request is prioritized with review navigation', (
      tester,
    ) async {
      final request = ConnectionRequest(
        id: 'request',
        senderUserId: MockUsers.sofiaId,
        recipientUserId: MockUsers.joseId,
        encounterId: encounter.id,
        createdAt: observedAt,
        status: ConnectionRequestStatus.pending,
      );
      await tester.pumpWidget(
        createHomeScreen(
          profileState: const AsyncValue.data(null),
          encounterState: AsyncValue.data([encounter]),
          requestState: AsyncValue.data([request]),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        findHomeText('Review request'),
        200,
        scrollable: findHomeScrollable(),
      );
      expect(findHomeText('1 person wants to connect'), findsOneWidget);
      await tester.tap(findHomeText('Review request'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        2,
      );
    });

    testWidgets('established connections have distinct product copy', (
      tester,
    ) async {
      await tester.pumpWidget(
        createHomeScreen(
          profileState: const AsyncValue.data(null),
          connectionState: AsyncValue.data([connection]),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        findHomeText("1 person you've connected with"),
        200,
        scrollable: findHomeScrollable(),
      );
      expect(findHomeText('No shared moments yet'), findsNothing);
    });

    testWidgets('recent conversation resolves context and opens its route', (
      tester,
    ) async {
      final conversation = Conversation(
        id: 'conversation',
        connectionId: connection.id,
        userAId: MockUsers.joseId,
        userBId: MockUsers.sofiaId,
        createdAt: observedAt,
        lastMessageAt: observedAt,
      );
      await tester.pumpWidget(
        createHomeScreen(
          profileState: const AsyncValue.data(null),
          connectionState: AsyncValue.data([connection]),
          conversationState: AsyncValue.data([conversation]),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        findHomeText('Recent conversations'),
        200,
        scrollable: findHomeScrollable(),
      );
      expect(findHomeText('Sofia'), findsOneWidget);
      expect(findHomeText('Urban Art Gallery Opening'), findsWidgets);
      await tester.tap(findHomeText('Sofia'));
      await tester.pumpAndSettle();
      expect(find.byType(ConversationScreen), findsOneWidget);
    });

    testWidgets('general conversation CTA opens the Chat branch', (
      tester,
    ) async {
      final conversation = Conversation(
        id: 'conversation',
        connectionId: connection.id,
        userAId: MockUsers.joseId,
        userBId: MockUsers.sofiaId,
        createdAt: observedAt,
      );
      await tester.pumpWidget(
        createHomeScreen(
          profileState: const AsyncValue.data(null),
          connectionState: AsyncValue.data([connection]),
          conversationState: AsyncValue.data([conversation]),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        findHomeText('Open chat'),
        200,
        scrollable: findHomeScrollable(),
      );
      await tester.tap(findHomeText('Open chat'));
      await tester.pumpAndSettle();

      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        3,
      );
    });

    testWidgets('loading never masquerades as an empty social state', (
      tester,
    ) async {
      await tester.pumpWidget(
        createHomeScreen(
          profileState: const AsyncValue.data(null),
          encounterState: const AsyncValue.loading(),
        ),
      );
      await tester.pump();
      await tester.scrollUntilVisible(
        findHomeText('Loading shared moments…'),
        200,
        scrollable: findHomeScrollable(),
      );
      expect(findHomeText('No shared moments yet'), findsNothing);
    });

    testWidgets('chat failure leaves profile and event discovery usable', (
      tester,
    ) async {
      await tester.pumpWidget(
        createHomeScreen(
          profileState: const AsyncValue.data(
            UserProfile(id: '1', displayName: 'Hector'),
          ),
          conversationState: AsyncValue.error(
            Exception('chat failed'),
            StackTrace.empty,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(findHomeText('Hi, Hector'), findsOneWidget);
      expect(findHomeText('Events near you'), findsOneWidget);
      await tester.scrollUntilVisible(
        findHomeText('Recent conversations are unavailable right now.'),
        200,
        scrollable: findHomeScrollable(),
      );
      expect(findHomeText('No shared moments yet'), findsOneWidget);
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
        'Upcoming activities',
        'Your connections',
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
