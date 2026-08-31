import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitzone/features/connections/domain/connection_repository.dart';
import 'package:mitzone/features/connections/data/connection_providers.dart';
import 'package:mitzone/features/encounters/data/encounter_providers.dart';
import 'package:mitzone/features/encounters/domain/encounter.dart';
import 'package:mitzone/features/profile/domain/user_profile.dart';
import 'package:mitzone/features/profile/presentation/other_user_profile_screen.dart';
import 'package:mitzone/core/identity/mock_identity_repository.dart';

void main() {
  final encounter = Encounter(
    id: 'jose-sofia-event-1',
    currentUserId: MockUsers.joseId,
    otherUserId: MockUsers.sofiaId,
    eventId: 'event-1',
    overlapStart: DateTime(2026, 8, 30, 10),
    overlapEnd: DateTime(2026, 8, 30, 11),
  );

  Widget buildScreen({RelationshipState state = RelationshipState.none}) {
    return ProviderScope(
      overrides: [
        encountersForCurrentUserProvider.overrideWith(
          (ref) async => [encounter],
        ),
        relationshipProvider(encounter).overrideWith((ref) async => state),
      ],
      child: MaterialApp(
        home: OtherUserProfileScreen(
          userId: MockUsers.sofiaId,
          encounterId: encounter.id,
        ),
      ),
    );
  }

  testWidgets('reconstructs from identifiers without navigation extra', (
    tester,
  ) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();
    expect(find.text('Sofia'), findsOneWidget);
    expect(find.text('Shared interests'), findsOneWidget);
    expect(find.text('Shared languages'), findsOneWidget);
    expect(find.text('Say Hi'), findsOneWidget);
  });

  testWidgets('handles unavailable encounter and optional fields safely', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          encountersForCurrentUserProvider.overrideWith((ref) async => []),
        ],
        child: const MaterialApp(
          home: OtherUserProfileScreen(
            userId: MockUsers.sofiaId,
            encounterId: 'missing',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('This encounter is no longer available.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final entry in const {
    RelationshipState.outgoingPending: 'Request sent',
    RelationshipState.incomingPending: 'Review this request in Matches',
    RelationshipState.declined: 'Not now',
  }.entries) {
    testWidgets('${entry.key} state is rendered', (tester) async {
      await tester.pumpWidget(buildScreen(state: entry.key));
      await tester.pumpAndSettle();
      expect(find.text(entry.value), findsOneWidget);
    });
  }
}
