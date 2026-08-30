/// How a presence was verified. Only manual/local demo is implemented today.
import '../../../core/errors/domain_error.dart';
enum EventCheckInMethod { manual, localDemo, qr, geofence }

class EventCheckIn {
  factory EventCheckIn({
    required this.eventId,
    required this.identityId,
    required this.checkedInAt,
    required this.method,
    this.checkedOutAt,
  }) {
    if (eventId.trim().isEmpty || identityId.trim().isEmpty || !checkedInAt.isUtc || (checkedOutAt != null && !checkedOutAt!.isUtc)) throw const DomainError(DomainErrorCode.validation, 'Check-in has invalid identity or timestamp');
    if (checkedOutAt != null && checkedOutAt!.isBefore(checkedInAt)) throw const DomainError(DomainErrorCode.validation, 'Check-in interval is reversed');
    return EventCheckIn._(eventId, identityId, checkedInAt, method, checkedOutAt);
  }
  const EventCheckIn._(this.eventId, this.identityId, this.checkedInAt, this.method, this.checkedOutAt);

  final String eventId;
  final String identityId;
  final DateTime checkedInAt;
  final EventCheckInMethod method;
  final DateTime? checkedOutAt;

  DateTime effectiveCheckedOutAt({DateTime? referenceTime}) =>
      checkedOutAt ?? (referenceTime ?? checkedInAt);
}

typedef Presence = EventCheckIn;
