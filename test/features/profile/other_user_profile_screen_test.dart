import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitzone/features/connections/domain/connection_repository.dart';
import 'package:mitzone/features/connections/data/connection_providers.dart';
import 'package:mitzone/features/encounters/data/encounter_providers.dart';
import 'package:mitzone/features/encounters/domain/encounter.dart';
import 'package:mitzone/features/encounters/domain/encounter_eligibility.dart';
import 'package:mitzone/features/blocking/data/block_providers.dart';
import 'package:mitzone/core/storage/storage_providers.dart';
import '../../support/memory_local_storage.dart';
import 'package:mitzone/features/profile/presentation/other_user_profile_screen.dart';
import 'package:mitzone/core/identity/mock_identity_repository.dart';
import 'package:mitzone/core/config/app_config.dart';
import 'package:mitzone/core/config/app_environment.dart';
import 'package:mitzone/core/providers/core_providers.dart';

void main() {
  final testNow = DateTime.utc(2026, 8, 30, 10, 30);
  final encounter = Encounter(
    id: 'jose-sofia-event-1',
    currentUserId: MockUsers.joseId,
    otherUserId: MockUsers.sofiaId,
    eventId: 'event-1',
    overlapStart: DateTime.utc(2026, 8, 30, 10),
    overlapEnd: DateTime.utc(2026, 8, 30, 11),
  );

  Widget buildScreen({
    RelationshipState state = RelationshipState.none,
    DateTime? now,
  }) {
    return ProviderScope(
      overrides: [
        localStorageProvider.overrideWithValue(MemoryLocalStorage()),
        appConfigProvider.overrideWithValue(
          AppConfig.validated(env: AppEnvironment.local),
        ),
        encountersForCurrentUserProvider.overrideWith((ref) async {
          final policy = EncounterEligibilityPolicy(
            ref.watch(blockRepositoryProvider),
            now: () => now ?? testNow,
          );
          return await policy.evaluate(encounter) ==
                  EncounterEligibility.actionable
              ? [encounter]
              : [];
        }),
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
    expect(find.text('Sofia'), findsNWidgets(2));
    expect(find.text('Shared interests'), findsNothing);
    expect(find.text('Shared languages'), findsNothing);
    // The public-profile DTO does not expose private affinity or trait data.
    expect(find.text('Personality'), findsNothing);
    expect(find.text('Why you crossed paths'), findsOneWidget);
    expect(find.text('Say Hi'), findsOneWidget);
  });

  testWidgets('handles unavailable encounter and optional fields safely', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(
            AppConfig.validated(env: AppEnvironment.local),
          ),
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

  testWidgets(
    'expired encounter cannot expose the profile or connection actions',
    (tester) async {
      await tester.pumpWidget(
        buildScreen(now: testNow.add(const Duration(hours: 1))),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('This encounter is no longer available.'),
        findsOneWidget,
      );
      expect(find.text('Sofia'), findsNothing);
      expect(find.text('Say Hi'), findsNothing);
    },
  );

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
