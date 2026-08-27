import '../../../core/identity/mock_identity_repository.dart';
import '../domain/event_check_in.dart';

/// Deterministic development-only presence data; it is not user-owned data.
final List<EventCheckIn> mockEventAttendees = [
  EventCheckIn(
    eventId: 'urban-art-opening',
    identityId: MockUsers.joseId,
    checkedInAt: DateTime.utc(2026, 8, 15, 18),
    checkedOutAt: DateTime.utc(2026, 8, 15, 21),
    method: EventCheckInMethod.manual,
  ),
  EventCheckIn(
    eventId: 'urban-art-opening',
    identityId: MockUsers.sofiaId,
    checkedInAt: DateTime.utc(2026, 8, 15, 19, 15),
    checkedOutAt: DateTime.utc(2026, 8, 15, 22),
    method: EventCheckInMethod.manual,
  ),
  EventCheckIn(
    eventId: 'urban-art-opening',
    identityId: MockUsers.emmaId,
    checkedInAt: DateTime.utc(2026, 8, 15, 20, 30),
    checkedOutAt: DateTime.utc(2026, 8, 15, 23),
    method: EventCheckInMethod.manual,
  ),
  EventCheckIn(
    eventId: 'urban-art-opening',
    identityId: MockUsers.danielId,
    checkedInAt: DateTime.utc(2026, 8, 15, 15),
    checkedOutAt: DateTime.utc(2026, 8, 15, 17, 30),
    method: EventCheckInMethod.manual,
  ),
];

List<EventCheckIn> mockAttendeesForEvent(String eventId) => [
  for (final presence in mockEventAttendees)
    if (presence.eventId == eventId) presence,
];
