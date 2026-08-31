import 'package:flutter_test/flutter_test.dart';
import 'package:mitzone/features/blocking/domain/block_repository.dart';
import 'package:mitzone/features/encounters/domain/encounter.dart';
import 'package:mitzone/features/encounters/domain/encounter_eligibility.dart';

class FakeBlocks implements BlockRepository {
  FakeBlocks(this.blocked);
  final bool blocked;
  @override
  Future<bool> isBlocked(String a, String b) async => blocked && a == 'a';
  @override
  Future<void> block({required String blockerUserId, required String blockedUserId}) async {}
  @override
  Future<void> unblock({required String blockerUserId, required String blockedUserId}) async {}
  @override
  Future<List<String>> getBlocked(String blockerUserId) async => const [];
}

Encounter encounter() => Encounter(
      id: 'e', currentUserId: 'a', otherUserId: 'b', eventId: 'event',
      overlapStart: DateTime.utc(2026, 1, 1),
      overlapEnd: DateTime.utc(2026, 1, 1, 1),
    );

void main() {
  test('blocked pair is unavailable and unblocked pair is actionable', () async {
    expect(await EncounterEligibilityPolicy(FakeBlocks(true)).evaluate(encounter()), EncounterEligibility.unavailable);
    expect(await EncounterEligibilityPolicy(FakeBlocks(false)).evaluate(encounter()), EncounterEligibility.actionable);
  });

  test('unavailable eligibility rejects sensitive actions', () async {
    expect(() => EncounterEligibilityPolicy(FakeBlocks(true)).requireActionable(encounter()), throwsA(isA<Exception>()));
  });
}
