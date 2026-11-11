import '../../../core/identity/mock_identity_repository.dart';
import '../domain/event_check_in.dart';

/// Deterministic development-only presence data relative to a local check-in.
///
/// Keeping the schedule relative lets the demo remain useful without weakening
/// the real interval-overlap rules used by the encounter engine.
List<EventCheckIn> mockAttendeesForEvent({
  required String eventId,
  required DateTime referenceTime,
}) {
  if (eventId != 'urban-art-opening') return const [];
  final anchor = referenceTime.toUtc();
  EventCheckIn presence(
    String identityId,
    Duration startsAfter,
    Duration endsAfter,
  ) => EventCheckIn(
    eventId: eventId,
    identityId: identityId,
    checkedInAt: anchor.add(startsAfter),
    checkedOutAt: anchor.add(endsAfter),
    method: EventCheckInMethod.manual,
  );

  return [
    presence(
      MockUsers.joseId,
      const Duration(minutes: -45),
      const Duration(hours: 2),
    ),
    presence(
      MockUsers.sofiaId,
      const Duration(minutes: -15),
      const Duration(hours: 2, minutes: 45),
    ),
    presence(
      MockUsers.emmaId,
      const Duration(minutes: 30),
      const Duration(hours: 3),
    ),
    presence(
      MockUsers.danielId,
      const Duration(hours: -3),
      const Duration(minutes: -30),
    ),
  ];
}
