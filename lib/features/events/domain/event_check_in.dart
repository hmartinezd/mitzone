enum EventCheckInMethod { localDemo }

class EventCheckIn {
  const EventCheckIn({
    required this.eventId,
    required this.identityId,
    required this.checkedInAt,
    required this.method,
  });

  final String eventId;
  final String identityId;
  final DateTime checkedInAt;
  final EventCheckInMethod method;
}
