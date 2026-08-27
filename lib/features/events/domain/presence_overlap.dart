import 'event_check_in.dart';

class PresenceOverlapResult {
  const PresenceOverlapResult({required this.overlaps, this.overlapStart, this.overlapEnd});
  final bool overlaps;
  final DateTime? overlapStart;
  final DateTime? overlapEnd;
  Duration get duration => overlaps && overlapStart != null && overlapEnd != null
      ? overlapEnd!.difference(overlapStart!)
      : Duration.zero;
}

abstract final class PresenceOverlap {
  static PresenceOverlapResult calculate(EventCheckIn a, EventCheckIn b) {
    final start = a.checkedInAt.isAfter(b.checkedInAt) ? a.checkedInAt : b.checkedInAt;
    final end = a.effectiveCheckedOutAt.isBefore(b.effectiveCheckedOutAt)
        ? a.effectiveCheckedOutAt : b.effectiveCheckedOutAt;
    if (!start.isBefore(end)) return const PresenceOverlapResult(overlaps: false);
    return PresenceOverlapResult(overlaps: true, overlapStart: start, overlapEnd: end);
  }
}
