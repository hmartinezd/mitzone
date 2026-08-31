import 'package:flutter_test/flutter_test.dart';
import 'package:mitzone/features/encounters/domain/presence_evidence.dart';
import 'package:mitzone/features/encounters/domain/presence_overlap.dart';

PresenceEvidence evidence(String user, String context, int start, int end) =>
    PresenceEvidence(
      id: '$user-$context-$start',
      subjectUserId: user,
      contextId: context,
      observedStart: DateTime.utc(2026, 1, 1, 10, start),
      observedEnd: DateTime.utc(2026, 1, 1, 10, end),
      source: PresenceEvidenceSource.eventParticipation,
    );

void main() {
  test('same context with meaningful overlap is a candidate', () {
    final overlap = PresenceOverlap.between(evidence('a', 'event', 0, 20), evidence('b', 'event', 10, 30));
    expect(overlap, isNotNull);
    expect(overlap!.duration, const Duration(minutes: 10));
  });

  test('short, different-context, and self overlaps are rejected', () {
    expect(PresenceOverlap.between(evidence('a', 'event', 0, 10), evidence('b', 'event', 8, 20)), isNull);
    expect(PresenceOverlap.between(evidence('a', 'event', 0, 20), evidence('b', 'other', 0, 20)), isNull);
    expect(PresenceOverlap.between(evidence('a', 'event', 0, 20), evidence('a', 'event', 0, 20)), isNull);
  });
}
