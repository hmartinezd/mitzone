import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitzone/core/config/app_config.dart';
import 'package:mitzone/core/auth/auth_providers.dart';
import 'package:mitzone/core/identity/current_user_provider.dart';
import 'package:mitzone/core/identity/identity_providers.dart';
import 'package:mitzone/core/config/app_environment.dart';
import 'package:mitzone/core/providers/core_providers.dart';
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
import 'package:mitzone/features/events/domain/event.dart';
import 'package:mitzone/features/encounters/data/foreground_location_sources.dart';
import 'package:mitzone/features/home/presentation/widgets/discovery_section.dart';
import 'package:mitzone/features/events/presentation/event_details_screen.dart';
import 'package:mitzone/app/theme/app_theme.dart';
import 'package:mitzone/features/home/presentation/home_screen.dart';
import 'package:mitzone/features/discovery/data/discovery_providers.dart';
import 'package:mitzone/features/discovery/domain/discovery_item.dart';
import 'package:mitzone/features/discovery/domain/discovery_repository.dart';
import 'package:mitzone/core/storage/local_storage.dart';
import 'package:mitzone/core/storage/storage_providers.dart';
import 'package:mitzone/features/events/data/demo_events.dart';
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
    AsyncValue<List<DiscoveryItem>> discoveryState = const AsyncValue.data([
      discoveryItem,
    ]),
    DiscoveryRepository? discoveryRepository,
    AsyncValue<List<Event>> eventState = const AsyncValue.data([]),
    double textScale = 1,
    bool darkTheme = false,
    bool production = false,
  }) {
    return ProviderScope(
      retry: (_, _) => null,
      overrides: [
        appConfigProvider.overrideWithValue(
          AppConfig.validated(env: AppEnvironment.local),
        ),
        localStorageProvider.overrideWithValue(_MemoryStorage()),
        if (production) ...[
          productionModeProvider.overrideWithValue(true),
          currentUserIdProvider.overrideWithValue(
            const AsyncValue.data('real-user'),
          ),
          mockIdentityRepositoryProvider.overrideWith(
            (ref) =>
                throw StateError('Production must not access demo identities'),
          ),
        ],
        if (discoveryRepository == null) ...[
          homeDiscoveryInterestsProvider.overrideWithValue(const <String>{}),
          nearbyDiscoveryProvider(
            const <String>{},
          ).overrideWithValue(discoveryState),
        ] else
          discoveryRepositoryProvider.overrideWithValue(discoveryRepository),
        nearbyEventsProvider.overrideWithValue(eventState),
        chatMessagesProvider(
          'conversation',
        ).overrideWithValue(const AsyncValue.data([])),
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
          return MaterialApp.router(
            theme: darkTheme ? AppTheme.darkTheme : null,
            routerConfig: router,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(textScale)),
              child: child!,
            ),
          );
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
        findHomeText('Go somewhere. Be present. Mitzone does the rest.'),
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
      await tester.pump(const Duration(milliseconds: 100));

      expect(findHomeText('Welcome back'), findsOneWidget);
      expect(findHomeText('Happening around you'), findsOneWidget);
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

  group('HomeScreen - Discovery', () {
    testWidgets('low activity emphasizes presence and discovery', (
      tester,
    ) async {
      await tester.pumpWidget(
        createHomeScreen(profileState: const AsyncValue.data(null)),
      );
      await tester.pumpAndSettle();
      expect(findHomeText('Where will you be?'), findsOneWidget);
      expect(findHomeText('I’m here'), findsOneWidget);
      expect(findHomeText('Happening around you'), findsOneWidget);
      expect(findHomeText('Upcoming activities'), findsNothing);
      expect(findHomeText('Events near you'), findsNothing);
      expect(findHomeText('Your connections'), findsNothing);
    });

    testWidgets('empty discovery does not render fabricated items', (
      tester,
    ) async {
      await tester.pumpWidget(
        createHomeScreen(
          profileState: const AsyncValue.data(null),
          discoveryState: const AsyncValue.data([]),
        ),
      );
      await tester.pumpAndSettle();
      expect(findHomeText('Nothing nearby was found yet.'), findsOneWidget);
      expect(findHomeText(discoveryItem.title), findsNothing);
    });

    testWidgets('loading discovery stays distinct from empty and error', (
      tester,
    ) async {
      await tester.pumpWidget(
        createHomeScreen(
          profileState: const AsyncValue.data(null),
          discoveryState: const AsyncValue.loading(),
        ),
      );
      // The indeterminate progress indicator intentionally never settles.
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(findHomeText('Nothing nearby was found yet.'), findsNothing);
      expect(
        findHomeText('We couldn’t load nearby discovery right now.'),
        findsNothing,
      );
    });

    testWidgets('discovery retry starts one new request and reaches success', (
      tester,
    ) async {
      final repository = _DiscoveryRepository();
      await tester.pumpWidget(
        createHomeScreen(
          profileState: const AsyncValue.data(
            UserProfile(id: '1', displayName: 'Hector', interests: ['Art']),
          ),
          discoveryRepository: repository,
        ),
      );
      repository.pending.completeError(Exception('failed'), StackTrace.empty);
      await tester.pump();
      await tester.pump();
      await tester.scrollUntilVisible(
        findHomeText('Try again'),
        200,
        scrollable: findHomeScrollable(),
      );
      expect(
        findHomeText('We couldn’t load nearby discovery right now.'),
        findsOneWidget,
      );
      repository.pending = Completer<List<DiscoveryItem>>();
      await tester.tap(findHomeText('Try again'));
      await tester.pump();
      repository.pending.complete([discoveryItem]);
      await tester.pumpAndSettle();
      expect(repository.calls, 2);
      expect(repository.interests, {'Art'});
      expect(findHomeText(discoveryItem.title), findsOneWidget);
      expect(
        findHomeText('We couldn’t load nearby discovery right now.'),
        findsNothing,
      );
    });

    testWidgets(
      'profile interests keep discovery request stable after completion',
      (tester) async {
        final repository = _DiscoveryRepository();
        await tester.pumpWidget(
          createHomeScreen(
            profileState: const AsyncValue.data(
              UserProfile(id: '1', displayName: 'Hector', interests: ['Art']),
            ),
            discoveryRepository: repository,
          ),
        );
        repository.pending.complete([discoveryItem]);
        await tester.pumpAndSettle();
        expect(repository.calls, 1);
        expect(repository.interests, {'Art'});
        expect(findHomeText(discoveryItem.title), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      },
    );
  });

  group('Home restoration', () {
    testWidgets(
      'Home controls have accessible labels and Android touch targets',
      (tester) async {
        final semantics = tester.ensureSemantics();
        try {
          await tester.pumpWidget(
            createHomeScreen(
              profileState: const AsyncData(
                UserProfile(id: '1', displayName: 'Hector'),
              ),
              darkTheme: true,
            ),
          );
          await tester.pumpAndSettle();
          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
          await expectLater(tester, meetsGuideline(textContrastGuideline));
        } finally {
          semantics.dispose();
        }
      },
    );

    testWidgets('headline remains primary when there is social activity', (
      tester,
    ) async {
      await tester.pumpWidget(
        createHomeScreen(
          profileState: const AsyncData(
            UserProfile(id: '1', displayName: 'Hector'),
          ),
          connectionState: AsyncData([
            Connection(
              id: 'c',
              userAId: MockUsers.joseId,
              userBId: MockUsers.sofiaId,
              encounterId: 'e',
              connectedAt: DateTime.utc(2026),
            ),
          ]),
          darkTheme: true,
        ),
      );
      await tester.pumpAndSettle();
      expect(findHomeText('Where will you be?'), findsOneWidget);
      expect(
        tester.getTopLeft(findHomeText('Where will you be?')).dy,
        lessThan(tester.getTopLeft(findHomeText('Happening around you')).dy),
      );
      expect(
        tester.getTopLeft(findHomeText('Happening around you')).dy,
        lessThan(
          tester.getTopLeft(findHomeText("1 person you've connected with")).dy,
        ),
      );
    });

    testWidgets('places remain informational without tap controls', (
      tester,
    ) async {
      await tester.pumpWidget(
        createHomeScreen(profileState: const AsyncData(null), darkTheme: true),
      );
      await tester.pumpAndSettle();
      final card = find
          .ancestor(
            of: findHomeText(discoveryItem.title),
            matching: find.byType(Card),
          )
          .first;
      expect(
        find.descendant(of: card, matching: find.byType(InkWell)),
        findsNothing,
      );
      expect(findHomeText('Photo unavailable'), findsOneWidget);
      expect(findHomeText('Google Maps'), findsOneWidget);
    });

    testWidgets('event metadata opens existing details and returns to Home', (
      tester,
    ) async {
      final event = demoEvents.first;
      await tester.pumpWidget(
        createHomeScreen(
          profileState: const AsyncData(null),
          eventState: AsyncData([event]),
        ),
      );
      await tester.pumpAndSettle();
      final title = findHomeText(event.title);
      await tester.ensureVisible(title);
      await tester.tap(title);
      await tester.pumpAndSettle();
      final details = tester.widget<EventDetailsScreen>(
        find.byType(EventDetailsScreen),
      );
      expect(details.eventId, event.id);
      expect(details.origin, EventDetailsOrigin.home);
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        0,
      );
    });

    testWidgets(
      'provider photography leads the carousel and preserves credits on image failure',
      (tester) async {
        const photo = 'https://images.example.test/provider-photo.jpg';
        final source = demoEvents.first;
        final event = Event(
          id: source.id,
          title: source.title,
          venue: source.venue,
          timeLabel: source.timeLabel,
          category: source.category,
          description: source.description,
          imageKey: photo,
          imageAttribution: 'Provider photo credit',
          source: 'ticketmaster',
        );
        await tester.pumpWidget(
          createHomeScreen(
            profileState: const AsyncData(null),
            eventState: AsyncData([event]),
            darkTheme: true,
          ),
        );
        await tester.pumpAndSettle();
        final carousel = tester.widget<DiscoverySection>(
          find.byType(DiscoverySection),
        );
        expect(carousel.items.first.id, event.id);
        expect(carousel.items.first.imageReference, photo);
        expect(findHomeText('Provider photo credit'), findsOneWidget);
        expect(findHomeText(event.title), findsOneWidget);
        // The widget harness rejects external HTTP. A failed image remains an
        // honest placeholder while retaining the real source metadata/destination.
        expect(findHomeText('Photo unavailable'), findsWidgets);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'partial event failure preserves places and retries without fake data',
      (tester) async {
        await tester.pumpWidget(
          createHomeScreen(
            profileState: const AsyncData(null),
            eventState: AsyncError(
              StateError('private provider details'),
              StackTrace.empty,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(findHomeText(discoveryItem.title), findsOneWidget);
        expect(
          findHomeText('We couldn’t load nearby discovery right now.'),
          findsOneWidget,
        );
        expect(find.textContaining('private provider'), findsNothing);
        expect(findHomeText('Nothing nearby was found yet.'), findsNothing);
      },
    );

    for (final failure in ForegroundLocationFailure.values) {
      testWidgets('discovery explains $failure independently of presence', (
        tester,
      ) async {
        await tester.pumpWidget(
          createHomeScreen(
            profileState: const AsyncData(null),
            discoveryState: AsyncError(
              ForegroundLocationException(failure),
              StackTrace.empty,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(findHomeText('Try again'), findsOneWidget);
        expect(findHomeText('I’m here'), findsOneWidget);
        expect(
          findHomeText('You’re discoverable here for a limited time.'),
          findsNothing,
        );
        if (failure == ForegroundLocationFailure.permissionPermanentlyDenied ||
            failure == ForegroundLocationFailure.servicesDisabled) {
          expect(findHomeText('Settings'), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('HomeScreen - Router Actions', () {
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

    testWidgets('Home -> Profile tab -> Profile (index 4)', (tester) async {
      const profile = UserProfile(id: '1', displayName: 'Hector');
      await tester.pumpWidget(
        createHomeScreen(profileState: const AsyncValue.data(profile)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.person_outline));
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

    testWidgets(
      'production social state does not expose demo identities or event context',
      (tester) async {
        await tester.pumpWidget(
          createHomeScreen(
            profileState: const AsyncValue.data(
              UserProfile(id: 'real-user', displayName: 'Hector'),
            ),
            encounterState: AsyncValue.data([encounter]),
            production: true,
          ),
        );
        await tester.pumpAndSettle();
        expect(findHomeText('Someone'), findsOneWidget);
        expect(findHomeText('Shared event'), findsOneWidget);
        expect(findHomeText('Sofia'), findsNothing);
        expect(findHomeText('Urban Art Gallery Opening'), findsNothing);
        expect(findHomeText('DEMO'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'social errors remain distinct from empty and preserve discovery',
      (tester) async {
        await tester.pumpWidget(
          createHomeScreen(
            profileState: const AsyncValue.data(null),
            encounterState: AsyncValue.data([encounter]),
            requestState: AsyncValue.error(
              Exception('requests failed'),
              StackTrace.empty,
            ),
            connectionState: AsyncValue.error(
              Exception('connections failed'),
              StackTrace.empty,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          findHomeText('Connection requests are unavailable right now.'),
          findsOneWidget,
        );
        expect(
          findHomeText('Your connections are unavailable right now.'),
          findsOneWidget,
        );
        expect(findHomeText('No shared moments yet'), findsNothing);
        expect(findHomeText('Happening around you'), findsOneWidget);
      },
    );

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
          connectionState: AsyncValue.data([connection]),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
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
          encounterState: AsyncValue.data([encounter]),
          conversationState: AsyncValue.error(
            Exception('chat failed'),
            StackTrace.empty,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(findHomeText('Hi, Hector'), findsOneWidget);
      expect(findHomeText('Happening around you'), findsOneWidget);
      await tester.scrollUntilVisible(
        findHomeText('Recent conversations are unavailable right now.'),
        200,
        scrollable: findHomeScrollable(),
      );
      expect(findHomeText('People you crossed paths with'), findsOneWidget);
    });
  });

  test('discovery interests update when profile interests change', () async {
    final container = ProviderContainer(
      overrides: [
        currentProfileProvider.overrideWithValue(
          const AsyncValue.data(
            UserProfile(id: '1', displayName: 'Hector', interests: ['Art']),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      homeDiscoveryInterestsProvider,
      (_, _) {},
    );
    addTearDown(subscription.close);
    expect(subscription.read(), {'Art'});
    container.updateOverrides([
      currentProfileProvider.overrideWithValue(
        const AsyncValue.data(
          UserProfile(id: '1', displayName: 'Hector', interests: ['Music']),
        ),
      ),
    ]);
    await container.pump();
    expect(subscription.read(), {'Music'});
  });

  group('HomeScreen - Responsive discovery', () {
    for (final size in [
      const Size(320, 480),
      const Size(414, 896),
      const Size(896, 414),
      const Size(1024, 768),
    ]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('no overflow at $size with ${scale}x text', (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await tester.pumpWidget(
            createHomeScreen(
              profileState: const AsyncValue.data(null),
              textScale: scale,
              darkTheme: true,
              discoveryState: const AsyncValue.data([
                discoveryItem,
                discoveryItem,
              ]),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final discoveryText = findHomeText('Happening around you');
          expect(
            MediaQuery.textScalerOf(tester.element(discoveryText)).scale(10),
            10 * scale,
          );
          for (final label in [
            'Welcome back',
            'Where will you be?',
            'I’m here',
            'Happening around you',
            'Google Maps',
            'DEMO',
          ]) {
            await tester.scrollUntilVisible(
              findHomeText(label).first,
              100,
              scrollable: findHomeScrollable(),
            );
            expect(findHomeText(label), findsWidgets);
            expect(tester.takeException(), isNull);
          }
          final cardTitle = findHomeText(discoveryItem.title).first;
          await tester.ensureVisible(cardTitle);
          await tester.dragFrom(
            tester.getCenter(cardTitle),
            const Offset(-280, 0),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        });
      }
    }
  });
}

const discoveryItem = DiscoveryItem(
  id: 'place',
  source: 'google-places',
  type: DiscoveryItemType.place,
  title: 'A nearby gallery with a long descriptive name',
  category: ['Arts and culture'],
  context: 'A neighborhood gathering place',
  subtitle: 'Open today for visitors',
  distanceKm: 1.2,
  imageReference: 'https://example.com/gallery.png',
);

class _DiscoveryRepository implements DiscoveryRepository {
  Completer<List<DiscoveryItem>> pending = Completer<List<DiscoveryItem>>();
  int calls = 0;
  Set<String>? interests;
  @override
  Future<List<DiscoveryItem>> getNearby({
    Set<String> interests = const {},
    double? latitude,
    double? longitude,
    DateTime? now,
  }) {
    calls++;
    this.interests = interests;
    return pending.future;
  }
}

class _MemoryStorage implements LocalStorage {
  final Map<String, Object> values = {};
  @override
  Future<String?> getString(String key) async => values[key] as String?;
  @override
  Future<bool?> getBool(String key) async => values[key] as bool?;
  @override
  Future<void> setString(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> setBool(String key, bool value) async {
    values[key] = value;
  }
}
