import 'package:flutter_test/flutter_test.dart';
import 'package:mitzone/core/identity/mock_identity_repository.dart';
import 'package:mitzone/features/events/data/mock_event_attendees.dart';
import 'package:mitzone/features/encounters/domain/encounter_engine.dart';

void main() {
  test('generates deterministic encounters for the active user', () {
    final jose = EncounterEngine(mockEventAttendees).forUser(MockUsers.joseId);
    expect(jose.map((e) => e.otherUserId), [MockUsers.emmaId, MockUsers.sofiaId]);
    expect(jose.first.overlapDuration, const Duration(minutes: 30));
  });

  test('does not create self or boundary encounters', () {
    final daniel = EncounterEngine(mockEventAttendees).forUser(MockUsers.danielId);
    expect(daniel, isEmpty);
  });
}
