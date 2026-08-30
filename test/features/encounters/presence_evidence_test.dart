import 'package:flutter_test/flutter_test.dart';
import 'package:mitzone/core/errors/domain_error.dart';
import 'package:mitzone/features/encounters/domain/encounter.dart';
import 'package:mitzone/features/encounters/domain/presence_evidence.dart';

void main() {
  test('presence evidence is bounded and UTC-aware', () {
    final evidence = PresenceEvidence(
      id: 'evidence-1', subjectUserId: 'user-a', contextId: 'event-1',
      observedStart: DateTime.utc(2026, 1, 1, 10),
      observedEnd: DateTime.utc(2026, 1, 1, 11),
      source: PresenceEvidenceSource.localDemo, confidence: 0.8,
    );
    expect(evidence.isUtc, isTrue);
  });

  test('encounters reject self-pairs and reversed intervals', () {
    expect(() => Encounter(id: 'e', currentUserId: 'a', otherUserId: 'a', eventId: 'event', overlapStart: DateTime.utc(2026), overlapEnd: DateTime.utc(2026)), throwsA(isA<DomainError>()));
    expect(() => PresenceEvidence(id: 'e', subjectUserId: 'a', contextId: 'event', observedStart: DateTime.utc(2026, 1, 2), observedEnd: DateTime.utc(2026, 1, 1), source: PresenceEvidenceSource.localDemo), throwsA(isA<DomainError>()));
  });
}
