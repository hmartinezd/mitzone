/// How a presence was verified. Only manual/local demo is implemented today.
enum EventCheckInMethod { manual, localDemo, qr, geofence }

class EventCheckIn {
  const EventCheckIn({
    required this.eventId,
    required this.identityId,
    required this.checkedInAt,
    required this.method,
    this.checkedOutAt,
  });

  final String eventId;
  final String identityId;
  final DateTime checkedInAt;
  final EventCheckInMethod method;
  final DateTime? checkedOutAt;

  DateTime get effectiveCheckedOutAt => checkedOutAt ?? DateTime.now().toUtc();
}

typedef Presence = EventCheckIn;
