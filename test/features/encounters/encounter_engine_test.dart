import 'package:flutter_test/flutter_test.dart';
import 'package:mitzone/core/identity/mock_identity_repository.dart';
import 'package:mitzone/features/events/data/mock_event_attendees.dart';
import 'package:mitzone/features/encounters/domain/encounter_engine.dart';
import 'package:mitzone/features/events/domain/event_check_in.dart';

void main() {
  test('generates deterministic encounters for the active user', () {
    final jose = EncounterEngine(mockEventAttendees).forUser(MockUsers.joseId);
    expect(jose.map((e) => e.otherUserId), [
      MockUsers.emmaId,
      MockUsers.sofiaId,
    ]);
    expect(jose.first.overlapDuration, const Duration(minutes: 30));
  });

  test('does not create self or boundary encounters', () {
    final daniel = EncounterEngine(
      mockEventAttendees,
    ).forUser(MockUsers.danielId);
    expect(daniel, isEmpty);
  });

  test('merges multiple compatible windows into one encounter', () {
    final start = DateTime.utc(2026, 8, 27, 10);
    final encounters = EncounterEngine([
      EventCheckIn(eventId: 'event', identityId: 'a', checkedInAt: start, checkedOutAt: start.add(const Duration(hours: 2)), method: EventCheckInMethod.localDemo),
      EventCheckIn(eventId: 'event', identityId: 'a', checkedInAt: start.add(const Duration(minutes: 30)), checkedOutAt: start.add(const Duration(hours: 3)), method: EventCheckInMethod.localDemo),
      EventCheckIn(eventId: 'event', identityId: 'b', checkedInAt: start.add(const Duration(minutes: 15)), checkedOutAt: start.add(const Duration(hours: 1)), method: EventCheckInMethod.localDemo),
    ]).forUser('a');
    expect(encounters, hasLength(1));
    expect(encounters.single.overlapStart, start.add(const Duration(minutes: 30)));
    expect(encounters.single.overlapEnd, start.add(const Duration(hours: 1)));
  });
}
