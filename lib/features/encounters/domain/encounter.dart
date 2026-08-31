import '../../../core/errors/domain_error.dart';

class Encounter {
  factory Encounter({
    required this.id,
    required this.currentUserId,
    required this.otherUserId,
    required this.eventId,
    required this.overlapStart,
    required this.overlapEnd,
  }) {
    if ([
          id,
          currentUserId,
          otherUserId,
          eventId,
        ].any((v) => v.trim().isEmpty) ||
        currentUserId == otherUserId) {
      throw const DomainError(
        DomainErrorCode.validation,
        'Encounter has invalid participants or identifiers',
      );
    }
    if (!overlapStart.isUtc ||
        !overlapEnd.isUtc ||
        overlapEnd.isBefore(overlapStart)) {
      throw const DomainError(
        DomainErrorCode.validation,
        'Encounter interval must be valid UTC',
      );
    }
    return Encounter._(
      id,
      currentUserId,
      otherUserId,
      eventId,
      overlapStart,
      overlapEnd,
    );
  }
  const Encounter._(
    this.id,
    this.currentUserId,
    this.otherUserId,
    this.eventId,
    this.overlapStart,
    this.overlapEnd,
  );
  final String id;
  final String currentUserId;
  final String otherUserId;
  final String eventId;
  final DateTime overlapStart;
  final DateTime overlapEnd;
  Duration get overlapDuration => overlapEnd.difference(overlapStart);
}
