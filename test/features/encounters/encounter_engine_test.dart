import 'package:flutter_test/flutter_test.dart';
import 'package:mitzone/core/identity/mock_identity_repository.dart';
import 'package:mitzone/features/events/data/mock_event_attendees.dart';
import 'package:mitzone/features/encounters/domain/encounter_engine.dart';
import 'package:mitzone/features/events/domain/event_check_in.dart';

void main() {
  test('generates deterministic attendee windows from a reference time', () {
    final anchor = DateTime.utc(2027, 3, 4, 12);
    final attendees = mockAttendeesForEvent(
      eventId: 'urban-art-opening',
      referenceTime: anchor,
    );
    expect(attendees, hasLength(4));
    expect(
      attendees.first.checkedInAt,
      anchor.subtract(const Duration(minutes: 45)),
    );
    expect(attendees.first.checkedOutAt, anchor.add(const Duration(hours: 2)));
  });

  test('does not invent attendees for an event without a demo schedule', () {
    expect(
      mockAttendeesForEvent(
        eventId: 'morning-yoga',
        referenceTime: DateTime.utc(2027, 3, 4, 12),
      ),
      isEmpty,
    );
  });

  test('demo encounters follow a non-August check-in with honest overlap', () {
    final checkedInAt = DateTime.utc(2027, 3, 4, 12);
    final observedAt = checkedInAt.add(const Duration(minutes: 45));
    final encounters = EncounterEngine([
      EventCheckIn(
        eventId: 'urban-art-opening',
        identityId: 'local-user',
        checkedInAt: checkedInAt,
        method: EventCheckInMethod.localDemo,
      ),
      ...mockAttendeesForEvent(
        eventId: 'urban-art-opening',
        referenceTime: checkedInAt,
      ),
    ]).forUser('local-user', referenceTime: observedAt);

    expect(encounters, hasLength(3));
    expect(
      encounters.map((encounter) => encounter.otherUserId),
      containsAll([MockUsers.emmaId, MockUsers.sofiaId, MockUsers.joseId]),
    );
    expect(
      encounters
          .singleWhere((e) => e.otherUserId == MockUsers.joseId)
          .overlapDuration,
      const Duration(minutes: 45),
    );
    expect(encounters.any((e) => e.otherUserId == MockUsers.danielId), isFalse);
  });

  test('merges multiple compatible windows into one encounter', () {
    final start = DateTime.utc(2026, 8, 27, 10);
    final encounters = EncounterEngine([
      EventCheckIn(
        eventId: 'event',
        identityId: 'a',
        checkedInAt: start,
        checkedOutAt: start.add(const Duration(hours: 2)),
        method: EventCheckInMethod.localDemo,
      ),
      EventCheckIn(
        eventId: 'event',
        identityId: 'a',
        checkedInAt: start.add(const Duration(minutes: 30)),
        checkedOutAt: start.add(const Duration(hours: 3)),
        method: EventCheckInMethod.localDemo,
      ),
      EventCheckIn(
        eventId: 'event',
        identityId: 'b',
        checkedInAt: start.add(const Duration(minutes: 15)),
        checkedOutAt: start.add(const Duration(hours: 1)),
        method: EventCheckInMethod.localDemo,
      ),
    ]).forUser('a');
    expect(encounters, hasLength(1));
    expect(
      encounters.single.overlapStart,
      start.add(const Duration(minutes: 15)),
    );
    expect(encounters.single.overlapEnd, start.add(const Duration(hours: 1)));
  });
}
