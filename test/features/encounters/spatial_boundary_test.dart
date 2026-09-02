import 'package:flutter_test/flutter_test.dart';
import 'package:mitzone/features/encounters/domain/presence_overlap.dart';
import 'package:mitzone/features/encounters/domain/presence_evidence.dart';

void main() {
  test('adjacent coarse cells are compatible', () {
    expect(PresenceOverlap.contextsCompatible('cell:10:20', 'cell:11:20'), isTrue);
  });
  test('distant cells and different event contexts are not compatible', () {
    expect(PresenceOverlap.contextsCompatible('cell:10:20', 'cell:12:20'), isFalse);
    expect(PresenceOverlap.contextsCompatible('event:a', 'event:b'), isFalse);
  });

  test('adjacent cells still require meaningful temporal overlap', () {
    PresenceEvidence evidence(String id, DateTime start, DateTime end) => PresenceEvidence(
      id: id,
      subjectUserId: id,
      contextId: id == 'a' ? 'cell:10:20' : 'cell:11:20',
      observedStart: start,
      observedEnd: end,
      source: PresenceEvidenceSource.geolocation,
    );
    final start = DateTime.utc(2026, 1, 1, 12);
    expect(
      PresenceOverlap.between(evidence('a', start, start.add(const Duration(minutes: 4))), evidence('b', start, start.add(const Duration(minutes: 4)))),
      isNull,
    );
    expect(
      PresenceOverlap.between(evidence('a', start, start.add(const Duration(minutes: 5))), evidence('b', start, start.add(const Duration(minutes: 5)))),
      isNotNull,
    );
  });
}
