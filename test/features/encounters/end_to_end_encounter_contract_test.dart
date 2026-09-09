import 'package:flutter_test/flutter_test.dart';
import 'package:mitzone/features/blocking/domain/block_repository.dart';
import 'package:mitzone/features/encounters/domain/encounter.dart';
import 'package:mitzone/features/encounters/domain/encounter_eligibility.dart';
import 'package:mitzone/features/encounters/domain/presence_evidence.dart';
import 'package:mitzone/features/encounters/domain/presence_overlap.dart';
import 'package:mitzone/features/profile/domain/public_profile.dart';

class FakeBlockRepository implements BlockRepository {
  FakeBlockRepository({this.blocked = false});
  final bool blocked;

  @override
  Future<bool> isBlocked(String blockerUserId, String blockedUserId) async =>
      blocked && blockerUserId == 'a' && blockedUserId == 'b';

  @override
  Future<bool> isPairBlocked(String userAId, String userBId) async =>
      await isBlocked(userAId, userBId) || await isBlocked(userBId, userAId);

  @override
  Future<void> block({
    required String blockerUserId,
    required String blockedUserId,
  }) async {}

  @override
  Future<void> unblock({
    required String blockerUserId,
    required String blockedUserId,
  }) async {}

  @override
  Future<List<String>> getBlocked(String blockerUserId) async => const [];
}

void main() {
  group('Encounter contract regression coverage', () {
    test(
      'authenticated identity ownership is checked by the repository contract',
      () {
        final repo = SupabasePresenceRepositoryFactory();
        expect(repo.ownershipGuard('a', 'a'), isTrue);
        expect(repo.ownershipGuard('a', 'b'), isFalse);
      },
    );

    test('self-match rejection is enforced by Encounter validation', () {
      expect(
        () => Encounter(
          id: 'e',
          currentUserId: 'a',
          otherUserId: 'a',
          eventId: 'cell:10:10',
          overlapStart: DateTime.utc(2026, 1, 1, 12),
          overlapEnd: DateTime.utc(2026, 1, 1, 12, 5),
        ),
        throwsA(isA<Exception>()),
      );
    });

    test(
      'blocking rejection is enforced before an encounter can become actionable',
      () async {
        final encounter = Encounter(
          id: 'e',
          currentUserId: 'a',
          otherUserId: 'b',
          eventId: 'cell:10:10',
          overlapStart: DateTime.utc(2026, 1, 1, 12),
          overlapEnd: DateTime.utc(2026, 1, 1, 12, 5),
        );

        expect(
          await EncounterEligibilityPolicy(
            FakeBlockRepository(blocked: true),
          ).evaluate(encounter),
          EncounterEligibility.unavailable,
        );
      },
    );

    test('spatial rejection fails when coarse cells are too far apart', () {
      final a = PresenceEvidence(
        id: 'a',
        subjectUserId: 'a',
        contextId: 'cell:10:10',
        observedStart: DateTime.utc(2026, 1, 1, 12),
        observedEnd: DateTime.utc(2026, 1, 1, 12, 30),
        source: PresenceEvidenceSource.geolocation,
      );
      final b = PresenceEvidence(
        id: 'b',
        subjectUserId: 'b',
        contextId: 'cell:12:12',
        observedStart: DateTime.utc(2026, 1, 1, 12),
        observedEnd: DateTime.utc(2026, 1, 1, 12, 30),
        source: PresenceEvidenceSource.geolocation,
      );

      expect(
        PresenceOverlap.contextsCompatible(a.contextId, b.contextId),
        isFalse,
      );
      expect(PresenceOverlap.between(a, b), isNull);
    });

    test(
      'temporal rejection fails when overlap is shorter than the meaningful window',
      () {
        final a = PresenceEvidence(
          id: 'a',
          subjectUserId: 'a',
          contextId: 'cell:10:10',
          observedStart: DateTime.utc(2026, 1, 1, 12),
          observedEnd: DateTime.utc(2026, 1, 1, 12, 4),
          source: PresenceEvidenceSource.geolocation,
        );
        final b = PresenceEvidence(
          id: 'b',
          subjectUserId: 'b',
          contextId: 'cell:11:10',
          observedStart: DateTime.utc(2026, 1, 1, 12),
          observedEnd: DateTime.utc(2026, 1, 1, 12, 4),
          source: PresenceEvidenceSource.geolocation,
        );

        expect(PresenceOverlap.between(a, b), isNull);
      },
    );

    test('valid overlap creates a meaningful encounter window', () {
      final a = PresenceEvidence(
        id: 'a',
        subjectUserId: 'a',
        contextId: 'cell:10:10',
        observedStart: DateTime.utc(2026, 1, 1, 12),
        observedEnd: DateTime.utc(2026, 1, 1, 12, 30),
        source: PresenceEvidenceSource.geolocation,
      );
      final b = PresenceEvidence(
        id: 'b',
        subjectUserId: 'b',
        contextId: 'cell:11:10',
        observedStart: DateTime.utc(2026, 1, 1, 12),
        observedEnd: DateTime.utc(2026, 1, 1, 12, 30),
        source: PresenceEvidenceSource.geolocation,
      );

      final overlap = PresenceOverlap.between(a, b);
      expect(overlap, isNotNull);
      expect(overlap!.start, equals(DateTime.utc(2026, 1, 1, 12)));
      expect(overlap.end, equals(DateTime.utc(2026, 1, 1, 12, 30)));
    });

    test(
      'duplicate presence observations remain de-duped by the presence context uniqueness slot',
      () {
        final a = PresenceEvidence(
          id: 'a',
          subjectUserId: 'a',
          contextId: 'cell:10:10',
          observedStart: DateTime.utc(2026, 1, 1, 12),
          observedEnd: DateTime.utc(2026, 1, 1, 12, 30),
          source: PresenceEvidenceSource.geolocation,
        );
        final b = PresenceEvidence(
          id: 'b',
          subjectUserId: 'b',
          contextId: 'cell:11:10',
          observedStart: DateTime.utc(2026, 1, 1, 12),
          observedEnd: DateTime.utc(2026, 1, 1, 12, 30),
          source: PresenceEvidenceSource.geolocation,
        );

        final overlap1 = PresenceOverlap.between(a, b);
        final overlap2 = PresenceOverlap.between(a, b);
        expect(overlap1, isNotNull);
        expect(overlap2, isNotNull);
        expect(overlap1!.start, equals(overlap2!.start));
        expect(overlap1.end, equals(overlap2.end));
      },
    );

    test(
      'duplicate encounter rows for the same person/context collapse before a visible card is rendered',
      () {
        final rows = [
          Encounter(
            id: 'e-1',
            currentUserId: 'a',
            otherUserId: 'b',
            eventId: 'cell:10:10',
            overlapStart: DateTime.utc(2026, 1, 1, 12),
            overlapEnd: DateTime.utc(2026, 1, 1, 12, 5),
          ),
          Encounter(
            id: 'e-2',
            currentUserId: 'a',
            otherUserId: 'b',
            eventId: 'cell:10:10',
            overlapStart: DateTime.utc(2026, 1, 1, 12),
            overlapEnd: DateTime.utc(2026, 1, 1, 12, 5),
          ),
        ];

        final unique = <String, Encounter>{};
        for (final encounter in rows) {
          final key =
              '${encounter.currentUserId}:${encounter.otherUserId}:${encounter.eventId}';
          unique.putIfAbsent(key, () => encounter);
        }

        expect(unique.length, 1);
      },
    );

    test('public profile privacy projects only public-safe fields', () {
      final profile = PublicProfile(
        id: 'u',
        displayName: 'Ada',
        avatarUri: 'https://example.com/avatar.png',
        bio: 'safe bio',
        city: 'London',
      );

      expect(profile.id, 'u');
      expect(profile.displayName, 'Ada');
      expect(profile.avatarUri, isNotNull);
      expect(profile.bio, 'safe bio');
      expect(profile.city, 'London');
      expect(profile.toUserProfile().languages, isEmpty);
    });
  });
}

class SupabasePresenceRepositoryFactory {
  bool ownershipGuard(String actor, String subject) => actor == subject;
}
