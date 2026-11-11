import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitzone/app/theme/app_theme.dart';
import 'package:mitzone/features/connections/data/connection_providers.dart';
import 'package:mitzone/features/connections/domain/connection_repository.dart';
import 'package:mitzone/features/encounters/data/encounter_providers.dart';
import 'package:mitzone/features/encounters/data/encounter_resolvers.dart';
import 'package:mitzone/features/encounters/domain/encounter.dart';
import 'package:mitzone/features/events/domain/event.dart';
import 'package:mitzone/features/matches/presentation/matches_screen.dart';
import 'package:mitzone/features/profile/domain/public_profile.dart';

void main() {
  Future<void> showEncounter(
    WidgetTester tester,
    String contextId, {
    Event? event,
  }) async {
    final encounter = Encounter(
      id: 'test-encounter',
      currentUserId: 'owner',
      otherUserId: 'peer',
      eventId: contextId,
      overlapStart: DateTime.utc(2026, 11, 4, 12),
      overlapEnd: DateTime.utc(2026, 11, 4, 12, 10),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          encountersForCurrentUserProvider.overrideWithValue(
            AsyncData([encounter]),
          ),
          incomingConnectionRequestsProvider.overrideWithValue(
            const AsyncData([]),
          ),
          encounterProfileProvider('owner').overrideWithValue(
            const AsyncData(
              PublicProfile(id: 'owner', displayName: 'Test Owner'),
            ),
          ),
          encounterProfileProvider('peer').overrideWithValue(
            const AsyncData(
              PublicProfile(id: 'peer', displayName: 'Test Peer'),
            ),
          ),
          encounterEventProvider(contextId).overrideWithValue(event),
          relationshipProvider(
            encounter,
          ).overrideWithValue(const AsyncData(RelationshipState.none)),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(body: MatchesScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'coarse GPS encounter remains actionable without an event catalog record',
    (tester) async {
      await showEncounter(tester, 'cell:123:456');
      expect(find.text('Test Peer'), findsOneWidget);
      expect(find.text('A shared area'), findsOneWidget);
      expect(
        find.text('Coarse presence overlap. Exact locations are not shown.'),
        findsOneWidget,
      );
      expect(find.text('Say Hi'), findsOneWidget);
      expect(find.text('View profile'), findsOneWidget);
      expect(find.textContaining('cell:'), findsNothing);
      expect(find.text('Shared event context'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('known event context retains its actual catalog title', (
    tester,
  ) async {
    await showEncounter(
      tester,
      'test-event',
      event: const Event(
        id: 'test-event',
        title: 'Fixture event title',
        venue: 'Fixture venue',
        timeLabel: 'Fixture date',
        category: 'Test',
        description: 'Test-only fixture',
      ),
    );
    expect(find.text('Fixture event title'), findsOneWidget);
    expect(find.text('Shared event context'), findsOneWidget);
    expect(find.text('A shared area'), findsNothing);
  });
  testWidgets('unavailable historical context does not hide a valid person', (
    tester,
  ) async {
    await showEncounter(tester, 'expired-provider-event');
    expect(find.text('Test Peer'), findsOneWidget);
    expect(
      find.text('Details about this past context are unavailable.'),
      findsOneWidget,
    );
    expect(find.text('Say Hi'), findsOneWidget);
  });
}
