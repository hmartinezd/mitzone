class Encounter {
  const Encounter({
    required this.id,
    required this.currentUserId,
    required this.otherUserId,
    required this.eventId,
    required this.overlapStart,
    required this.overlapEnd,
  }) : assert(id != ''), assert(currentUserId != ''), assert(otherUserId != ''), assert(currentUserId != otherUserId), assert(eventId != ''), assert(!overlapEnd.isBefore(overlapStart));
  final String id;
  final String currentUserId;
  final String otherUserId;
  final String eventId;
  final DateTime overlapStart;
  final DateTime overlapEnd;
  Duration get overlapDuration => overlapEnd.difference(overlapStart);
}
