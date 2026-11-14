import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitzone/app/theme/app_theme.dart';
import 'package:mitzone/core/auth/auth_providers.dart';
import 'package:mitzone/core/identity/current_user_provider.dart';
import 'package:mitzone/features/connections/data/connection_providers.dart';
import 'package:mitzone/features/connections/domain/connection.dart';
import 'package:mitzone/features/connections/domain/connection_repository.dart';
import 'package:mitzone/features/connections/domain/connection_request.dart';
import 'package:mitzone/features/encounters/data/encounter_providers.dart';
import 'package:mitzone/features/encounters/data/encounter_resolvers.dart';
import 'package:mitzone/features/encounters/domain/encounter.dart';
import 'package:mitzone/features/matches/presentation/matches_screen.dart';
import 'package:mitzone/features/profile/domain/public_profile.dart';

class _ControlledRepository implements ConnectionRepository {
  final pending = Completer<ConnectionRequest>();
  int sends = 0, accepts = 0, declines = 0;
  @override
  Future<ConnectionRequest> sendRequest({
    required String senderUserId,
    required String recipientUserId,
    required String encounterId,
    String? contextId,
  }) {
    sends++;
    return pending.future;
  }

  @override
  Future<ConnectionRequest> acceptRequest({
    required String requestId,
    required String recipientUserId,
  }) {
    accepts++;
    return pending.future;
  }

  @override
  Future<ConnectionRequest> declineRequest({
    required String requestId,
    required String recipientUserId,
  }) {
    declines++;
    return pending.future;
  }

  @override
  Future<List<ConnectionRequest>> getIncomingRequests(String userId) async =>
      [];
  @override
  Future<List<ConnectionRequest>> getOutgoingRequests(String userId) async =>
      [];
  @override
  Future<List<Connection>> getConnections(String userId) async => [];
  @override
  Future<ConnectionRequest?> getRelationship({
    required String userAId,
    required String userBId,
    required String encounterId,
    String? contextId,
  }) async => null;
  @override
  Future<RelationshipState> getRelationshipState({
    required String userAId,
    required String userBId,
    String? contextId,
    String? encounterId,
  }) async => RelationshipState.none;
  @override
  Future<void> removeConnection({
    required String connectionId,
    required String userId,
  }) async {}
}

void main() {
  Future<void> showMatches(
    WidgetTester tester,
    _ControlledRepository repo, {
    bool incoming = false,
    bool includeEncounter = false,
  }) async {
    final encounter = Encounter(
      id: 'test-encounter',
      currentUserId: 'owner',
      otherUserId: 'peer',
      eventId: 'cell:1:1',
      overlapStart: DateTime.utc(2026, 11, 4),
      overlapEnd: DateTime.utc(2026, 11, 4, 0, 10),
    );
    final request = ConnectionRequest(
      id: 'test-request',
      senderUserId: 'peer',
      recipientUserId: 'owner',
      encounterId: encounter.id,
      createdAt: DateTime.utc(2026, 11, 4),
      status: ConnectionRequestStatus.pending,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          productionModeProvider.overrideWithValue(true),
          currentUserIdProvider.overrideWithValue(const AsyncData('owner')),
          connectionRepositoryProvider.overrideWithValue(repo),
          encountersForCurrentUserProvider.overrideWithValue(
            AsyncData(incoming && !includeEncounter ? [] : [encounter]),
          ),
          incomingConnectionRequestsProvider.overrideWithValue(
            AsyncData(incoming ? [request] : []),
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
          encounterEventProvider(encounter.eventId).overrideWithValue(null),
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

  testWidgets('request includes authorized coarse context beside decision', (
    tester,
  ) async {
    await showMatches(
      tester,
      _ControlledRepository(),
      incoming: true,
      includeEncounter: true,
    );
    expect(
      find.text(
        'You crossed paths in a shared area. Exact locations are not shown.',
      ),
      findsOneWidget,
    );
    expect(find.text('Accept'), findsOneWidget);
    expect(find.textContaining('cell:'), findsNothing);
  });

  testWidgets(
    'request without matching encounter has honest context fallback',
    (tester) async {
      await showMatches(tester, _ControlledRepository(), incoming: true);
      expect(
        find.text('Shared experience details are unavailable.'),
        findsOneWidget,
      );
      expect(find.text('Accept'), findsOneWidget);
    },
  );

  testWidgets(
    'failed send is awaited, disables duplicate submit and offers retry',
    (tester) async {
      final repo = _ControlledRepository();
      await showMatches(tester, repo);
      await tester.ensureVisible(find.text('Say Hi'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Say Hi'));
      await tester.pump();
      await tester.pump();
      expect(repo.sends, 1);
      expect(
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, 'Sending…'))
            .onPressed,
        isNull,
      );
      repo.pending.completeError(StateError('fixture failure'));
      await tester.pumpAndSettle();
      expect(
        find.text('We could not send your request. Please try again.'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, 'Say Hi'))
            .onPressed,
        isNotNull,
      );
      expect(tester.takeException(), isNull);
    },
  );
  for (final accept in [true, false]) {
    testWidgets(
      'failed ${accept ? 'accept' : 'decline'} disables both decisions and retains pending request',
      (tester) async {
        final repo = _ControlledRepository();
        await showMatches(tester, repo, incoming: true);
        await tester.tap(find.text(accept ? 'Accept' : 'Not now'));
        await tester.pump();
        await tester.pump();
        expect(accept ? repo.accepts : repo.declines, 1);
        expect(
          tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
          isNull,
        );
        expect(
          tester
              .widget<TextButton>(
                find.widgetWithText(
                  TextButton,
                  accept ? 'Not now' : 'Updating…',
                ),
              )
              .onPressed,
          isNull,
        );
        repo.pending.completeError(StateError('fixture failure'));
        await tester.pumpAndSettle();
        expect(
          find.text('We could not update this request. Please try again.'),
          findsOneWidget,
        );
        expect(find.text('Accept'), findsOneWidget);
        expect(find.text('Not now'), findsOneWidget);
        expect(
          tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
          isNotNull,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
