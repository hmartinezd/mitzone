import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitzone/app/router/app_router.dart';
import 'package:mitzone/app/router/app_routes.dart';
import 'package:mitzone/core/identity/app_identity.dart';
import 'package:mitzone/core/identity/identity_gateway.dart';
import 'package:mitzone/core/identity/identity_providers.dart';
import 'package:mitzone/features/events/data/event_providers.dart';
import 'package:mitzone/features/events/domain/event_participation_repository.dart';
import 'package:mitzone/features/events/presentation/event_details_screen.dart';

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

  @override
  Future<Set<String>> getJoinedEventIds(String identityId) async => {
    ...?idsByIdentity[identityId],
  };

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

void main() {
  Widget appAt(String location, TestParticipationRepository repository) {
    return ProviderScope(
      overrides: [
        routerInitialLocationProvider.overrideWithValue(location),
        identityGatewayProvider.overrideWithValue(TestIdentityGateway()),
        eventParticipationRepositoryProvider.overrideWithValue(repository),
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
