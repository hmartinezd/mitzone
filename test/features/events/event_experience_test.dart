import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitzone/app/router/app_router.dart';
import 'package:mitzone/app/router/app_routes.dart';
import 'package:mitzone/core/identity/app_identity.dart';
import 'package:mitzone/core/identity/identity_gateway.dart';
import 'package:mitzone/core/identity/identity_providers.dart';
import 'package:mitzone/features/events/data/event_providers.dart';
import 'package:mitzone/features/events/domain/event_check_in.dart';
import 'package:mitzone/features/events/domain/event_check_in_repository.dart';
import 'package:mitzone/features/events/domain/event_participation_repository.dart';
import 'package:mitzone/features/events/presentation/event_details_screen.dart';
import 'package:mitzone/features/home/presentation/home_screen.dart';
import 'package:mitzone/features/home/presentation/widgets/home_event_card.dart';
import 'package:mitzone/features/home/presentation/widgets/home_event_section.dart';

class TestIdentityGateway implements IdentityGateway {
  static const identity = AppIdentity(
    id: 'identity-a',
    type: AppIdentityType.localDevelopment,
  );

  @override
  Future<AppIdentity> ensureIdentity() async => identity;

  @override
  Future<AppIdentity?> getExistingIdentity() async => identity;
}

class TestParticipationRepository implements EventParticipationRepository {
  final idsByIdentity = <String, Set<String>>{};
  bool failMutations = false;
  bool failLoads = false;

  @override
  Future<Set<String>> getJoinedEventIds(String identityId) async {
    if (failLoads) throw Exception('read failed');
    return {...?idsByIdentity[identityId]};
  }

  @override
  Future<bool> isJoined({
    required String identityId,
    required String eventId,
  }) async => idsByIdentity[identityId]?.contains(eventId) ?? false;

  @override
  Future<void> join({
    required String identityId,
    required String eventId,
  }) async {
    if (failMutations) throw Exception('write failed');
    idsByIdentity.putIfAbsent(identityId, () => {}).add(eventId);
  }

  @override
  Future<void> leave({
    required String identityId,
    required String eventId,
  }) async {
    if (failMutations) throw Exception('write failed');
    idsByIdentity[identityId]?.remove(eventId);
  }
}

class TestCheckInRepository implements EventCheckInRepository {
  final records = <EventCheckIn>[];
  bool failLoads = false;
  bool failMutations = false;

  @override
  Future<EventCheckIn?> getCheckIn({
    required String identityId,
    required String eventId,
  }) async {
    for (final record in await getCheckIns(identityId)) {
      if (record.eventId == eventId) return record;
    }
    return null;
  }

  @override
  Future<List<EventCheckIn>> getCheckIns(String identityId) async {
    if (failLoads) throw Exception('read failed');
    return records.where((record) => record.identityId == identityId).toList();
  }

  @override
  Future<void> recordCheckIn(EventCheckIn checkIn) async {
    if (failMutations) throw Exception('write failed');
    if (records.any(
      (record) =>
          record.identityId == checkIn.identityId &&
          record.eventId == checkIn.eventId,
    )) {
      return;
    }
    records.add(checkIn);
  }
}

void main() {
  Widget appAt(
    String location,
    TestParticipationRepository repository, {
    TestCheckInRepository? checkIns,
  }) {
    return ProviderScope(
      overrides: [
        routerInitialLocationProvider.overrideWithValue(location),
        identityGatewayProvider.overrideWithValue(TestIdentityGateway()),
        eventParticipationRepositoryProvider.overrideWithValue(repository),
        eventCheckInRepositoryProvider.overrideWithValue(
          checkIns ?? TestCheckInRepository(),
        ),
        utcNowProvider.overrideWithValue(
          () => DateTime.utc(2026, 8, 21, 23, 42),
        ),
      ],
      child: Consumer(
        builder: (context, ref, child) =>
            MaterialApp.router(routerConfig: ref.watch(routerProvider)),
      ),
    );
  }

  Future<void> revealAndTap(WidgetTester tester, String text) async {
    final scrollable = find
        .descendant(
          of: find.byType(EventDetailsScreen),
          matching: find.byWidgetPredicate(
            (widget) => widget is Scrollable && widget.axis == Axis.vertical,
          ),
        )
        .first;
    await tester.scrollUntilVisible(
      find.text(text),
      200,
      scrollable: scrollable,
    );
    await tester.tap(find.text(text));
  }

  testWidgets('events card opens details in the Events branch and backs', (
    tester,
  ) async {
    await tester.pumpWidget(
      appAt(AppRoutes.events, TestParticipationRepository()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tech Mixer 2026'));
    await tester.pumpAndSettle();

    expect(find.byType(EventDetailsScreen), findsOneWidget);
    expect(find.text('About this event'), findsOneWidget);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      1,
    );

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text("Discover what's happening."), findsOneWidget);
  });

  testWidgets('direct valid and invalid routes are safe', (tester) async {
    await tester.pumpWidget(
      appAt('/app/events/live-jazz-night', TestParticipationRepository()),
    );
    await tester.pumpAndSettle();
    expect(find.text('Live Jazz Night'), findsOneWidget);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      1,
    );

    await tester.pumpWidget(
      appAt('/app/events/not-real', TestParticipationRepository()),
    );
    await tester.pumpAndSettle();
    expect(find.text('Event not found.'), findsOneWidget);
    expect(find.text('Back to events'), findsOneWidget);
  });

  testWidgets('join and leave persist and refresh the detail state', (
    tester,
  ) async {
    final repository = TestParticipationRepository();
    await tester.pumpWidget(appAt('/app/events/tech-mixer-2026', repository));
    await tester.pumpAndSettle();

    await revealAndTap(tester, 'Join event');
    await tester.pumpAndSettle();
    expect(find.text("You're participating"), findsOneWidget);
    expect(repository.idsByIdentity['identity-a'], {'tech-mixer-2026'});

    await revealAndTap(tester, 'Leave event');
    await tester.pumpAndSettle();
    expect(find.text('Join event'), findsOneWidget);
    expect(repository.idsByIdentity['identity-a'], isEmpty);
  });

  testWidgets('failed join preserves state and allows retry', (tester) async {
    final repository = TestParticipationRepository()..failMutations = true;
    await tester.pumpWidget(appAt('/app/events/tech-mixer-2026', repository));
    await tester.pumpAndSettle();

    await revealAndTap(tester, 'Join event');
    await tester.pumpAndSettle();
    expect(find.text('Join event'), findsOneWidget);
    expect(
      find.text("We couldn't join this event. Please try again."),
      findsOneWidget,
    );

    repository.failMutations = false;
    await revealAndTap(tester, 'Join event');
    await tester.pumpAndSettle();
    expect(find.text("You're participating"), findsOneWidget);
  });

  testWidgets('failed leave preserves joined state and allows retry', (
    tester,
  ) async {
    final repository = TestParticipationRepository()
      ..idsByIdentity['identity-a'] = {'tech-mixer-2026'}
      ..failMutations = true;
    await tester.pumpWidget(appAt('/app/events/tech-mixer-2026', repository));
    await tester.pumpAndSettle();

    await revealAndTap(tester, 'Leave event');
    await tester.pumpAndSettle();
    expect(find.text("You're participating"), findsOneWidget);
    expect(find.text('Leave event'), findsOneWidget);
    expect(
      find.text("We couldn't update your participation. Please try again."),
      findsOneWidget,
    );

    repository.failMutations = false;
    await revealAndTap(tester, 'Leave event');
    await tester.pumpAndSettle();
    expect(find.text('Join event'), findsOneWidget);
  });

  testWidgets('check-in requires participation and records persistent status', (
    tester,
  ) async {
    final participation = TestParticipationRepository();
    final checkIns = TestCheckInRepository();
    await tester.pumpWidget(
      appAt('/app/events/tech-mixer-2026', participation, checkIns: checkIns),
    );
    await tester.pumpAndSettle();
    expect(find.text('Join this event to enable check-in.'), findsOneWidget);
    expect(find.text('Local demo check-in'), findsNothing);

    await revealAndTap(tester, 'Join event');
    await tester.pumpAndSettle();
    expect(find.text('Local demo check-in'), findsOneWidget);
    await revealAndTap(tester, 'Local demo check-in');
    await tester.pumpAndSettle();
    expect(find.text('✓ Checked in locally'), findsOneWidget);
    expect(find.text('Local demo check-in'), findsNothing);
    expect(checkIns.records.single.identityId, 'identity-a');
    expect(
      checkIns.records.single.checkedInAt,
      DateTime.utc(2026, 8, 21, 23, 42),
    );

    await revealAndTap(tester, 'Leave event');
    await tester.pumpAndSettle();
    expect(find.text('Join event'), findsOneWidget);
    expect(participation.idsByIdentity['identity-a'], isEmpty);
    expect(find.text('✓ Checked in locally'), findsOneWidget);
    expect(find.text('Local demo check-in'), findsNothing);
    expect(checkIns.records, hasLength(1));
    expect(
      checkIns.records.single.checkedInAt,
      DateTime.utc(2026, 8, 21, 23, 42),
    );
  });

  testWidgets('check-in mutation failure preserves action and allows retry', (
    tester,
  ) async {
    final participation = TestParticipationRepository()
      ..idsByIdentity['identity-a'] = {'tech-mixer-2026'};
    final checkIns = TestCheckInRepository()..failMutations = true;
    await tester.pumpWidget(
      appAt('/app/events/tech-mixer-2026', participation, checkIns: checkIns),
    );
    await tester.pumpAndSettle();
    await revealAndTap(tester, 'Local demo check-in');
    await tester.pumpAndSettle();
    expect(find.text('Local demo check-in'), findsOneWidget);
    expect(
      find.text("We couldn't record your check-in. Please try again."),
      findsOneWidget,
    );
    checkIns.failMutations = false;
    await revealAndTap(tester, 'Local demo check-in');
    await tester.pumpAndSettle();
    expect(find.text('✓ Checked in locally'), findsOneWidget);
  });

  testWidgets('check-in load failure is isolated and retryable', (
    tester,
  ) async {
    final participation = TestParticipationRepository()
      ..idsByIdentity['identity-a'] = {'tech-mixer-2026'};
    final checkIns = TestCheckInRepository()..failLoads = true;
    await tester.pumpWidget(
      appAt('/app/events/tech-mixer-2026', participation, checkIns: checkIns),
    );
    await tester.pumpAndSettle();
    expect(find.text('Tech Mixer 2026'), findsOneWidget);
    expect(find.text("We couldn't load your check-in status."), findsOneWidget);
    checkIns.failLoads = false;
    await revealAndTap(tester, 'Try again');
    await tester.pumpAndSettle();
    expect(find.text('Local demo check-in'), findsOneWidget);
  });

  testWidgets('participation error keeps event content and retry succeeds', (
    tester,
  ) async {
    final repository = TestParticipationRepository()..failLoads = true;
    await tester.pumpWidget(appAt('/app/events/tech-mixer-2026', repository));
    await tester.pumpAndSettle();
    expect(find.text('Tech Mixer 2026'), findsOneWidget);
    expect(find.text('The Innovation Hub'), findsOneWidget);
    expect(find.textContaining('Meet curious builders'), findsOneWidget);
    expect(find.text("We couldn't load your participation."), findsOneWidget);

    repository.failLoads = false;
    await revealAndTap(tester, 'Try again');
    await tester.pumpAndSettle();
    expect(find.text('Join event'), findsOneWidget);
  });

  testWidgets('historical check-in remains visible on participation failure', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final participation = TestParticipationRepository()..failLoads = true;
    final checkIns = TestCheckInRepository()
      ..records.add(
        EventCheckIn(
          eventId: 'tech-mixer-2026',
          identityId: 'identity-a',
          checkedInAt: DateTime.utc(2026, 8, 21, 23, 42),
          method: EventCheckInMethod.localDemo,
        ),
      );
    await tester.pumpWidget(
      appAt('/app/events/tech-mixer-2026', participation, checkIns: checkIns),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tech Mixer 2026'), findsOneWidget);
    expect(find.text("We couldn't load your participation."), findsOneWidget);
    expect(find.text('✓ Checked in locally'), findsOneWidget);
    expect(find.textContaining('Recorded '), findsOneWidget);
    expect(find.text('Local demo check-in'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('✓ Checked in locally'),
      200,
      scrollable: find
          .descendant(
            of: find.byType(EventDetailsScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label == 'Checked in locally to Tech Mixer 2026',
      ),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('participation semantics match the available actions', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final repository = TestParticipationRepository();
    await tester.pumpWidget(appAt('/app/events/tech-mixer-2026', repository));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Join event'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    Finder semanticsWithLabel(String label) => find.byWidgetPredicate(
      (widget) => widget is Semantics && widget.properties.label == label,
    );
    expect(semanticsWithLabel('Join Tech Mixer 2026'), findsOneWidget);
    await tester.tap(find.text('Join event'));
    await tester.pumpAndSettle();
    expect(
      semanticsWithLabel('Participating in Tech Mixer 2026'),
      findsOneWidget,
    );
    expect(semanticsWithLabel('Leave Tech Mixer 2026'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('Home event details backs to Home with Home selected', (
    tester,
  ) async {
    await tester.pumpWidget(
      appAt(AppRoutes.home, TestParticipationRepository()),
    );
    await tester.pumpAndSettle();
    final homeScrollable = find
        .descendant(
          of: find.byType(HomeScreen),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.text('Tech Mixer 2026').first,
      200,
      scrollable: homeScrollable,
    );
    await tester.tap(
      find.bySemanticsLabel(
        'Tech Mixer 2026. Networking. The Innovation Hub. Tonight, 7:00 PM.',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(EventDetailsScreen), findsOneWidget);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      1,
    );
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      0,
    );
  });

  testWidgets('join and leave synchronize Home without manual refresh', (
    tester,
  ) async {
    final repository = TestParticipationRepository();
    await tester.pumpWidget(appAt(AppRoutes.home, repository));
    await tester.pumpAndSettle();
    final navigationBar = find.byType(NavigationBar);
    await tester.tap(
      find.descendant(of: navigationBar, matching: find.text('Events')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tech Mixer 2026'));
    await tester.pumpAndSettle();
    await revealAndTap(tester, 'Join event');
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(of: navigationBar, matching: find.text('Home')),
    );
    await tester.pumpAndSettle();

    final upcoming = find.byWidgetPredicate(
      (widget) =>
          widget is HomeEventSection && widget.title == 'Upcoming activities',
    );
    expect(upcoming, findsOneWidget);
    expect(
      find.descendant(of: upcoming, matching: find.text('Tech Mixer 2026')),
      findsOneWidget,
    );

    final homeScrollable = find
        .descendant(
          of: find.byType(HomeScreen),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.descendant(of: upcoming, matching: find.text('Tech Mixer 2026')),
      200,
      scrollable: homeScrollable,
    );
    await tester.tap(
      find.descendant(of: upcoming, matching: find.byType(HomeEventCard)),
    );
    await tester.pumpAndSettle();
    await revealAndTap(tester, 'Leave event');
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(of: navigationBar, matching: find.text('Home')),
    );
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is HomeEventSection && widget.title == 'Upcoming activities',
      ),
      findsNothing,
    );
    expect(find.text('No upcoming activities yet.'), findsOneWidget);
  });

  testWidgets('Events and joined details remain usable at 320x480 and 2.0x', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });
    final repository = TestParticipationRepository()
      ..idsByIdentity['identity-a'] = {'tech-mixer-2026'};
    await tester.pumpWidget(appAt(AppRoutes.events, repository));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Tech Mixer 2026'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tech Mixer 2026'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Back'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Leave event'),
      200,
      scrollable: find
          .descendant(
            of: find.byType(EventDetailsScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text("You're participating"), findsOneWidget);
    expect(find.text('Leave event'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Local demo check-in'),
      200,
      scrollable: find
          .descendant(
            of: find.byType(EventDetailsScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('Local demo check-in'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label ==
                'Local demo check-in for Tech Mixer 2026',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Local demo check-in'));
    await tester.pumpAndSettle();
    expect(find.text('✓ Checked in locally'), findsOneWidget);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('checked-in details remain usable at a compact viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final checkIns = TestCheckInRepository()
      ..records.add(
        EventCheckIn(
          eventId: 'tech-mixer-2026',
          identityId: 'identity-a',
          checkedInAt: DateTime.utc(2026, 8, 21, 23, 42),
          method: EventCheckInMethod.localDemo,
        ),
      );
    await tester.pumpWidget(
      appAt(
        '/app/events/tech-mixer-2026',
        TestParticipationRepository(),
        checkIns: checkIns,
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('✓ Checked in locally'),
      200,
      scrollable: find
          .descendant(
            of: find.byType(EventDetailsScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('✓ Checked in locally'), findsOneWidget);
    expect(find.text('Local demo check-in'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final size in [
    const Size(320, 480),
    const Size(414, 896),
    const Size(896, 414),
    const Size(1024, 768),
  ]) {
    testWidgets('events and details fit ${size.width}x${size.height}', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        appAt(AppRoutes.events, TestParticipationRepository()),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Tech Mixer 2026'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Join event'), findsOneWidget);
    });
  }
}
