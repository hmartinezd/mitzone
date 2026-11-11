import 'event_check_in.dart';

class PresenceOverlapResult {
  const PresenceOverlapResult({
    required this.overlaps,
    this.overlapStart,
    this.overlapEnd,
  });
  final bool overlaps;
  final DateTime? overlapStart;
  final DateTime? overlapEnd;
  Duration get duration =>
      overlaps && overlapStart != null && overlapEnd != null
      ? overlapEnd!.difference(overlapStart!)
      : Duration.zero;
}

abstract final class PresenceOverlap {
  static PresenceOverlapResult calculate(
    EventCheckIn a,
    EventCheckIn b, {
    DateTime? referenceTime,
  }) {
    final start = a.checkedInAt.isAfter(b.checkedInAt)
        ? a.checkedInAt
        : b.checkedInAt;
    final aEnd = _effectiveEnd(a, b, referenceTime);
    final bEnd = _effectiveEnd(b, a, referenceTime);
    final end = aEnd.isBefore(bEnd) ? aEnd : bEnd;
    if (!start.isBefore(end)) {
      return const PresenceOverlapResult(overlaps: false);
    }
    return PresenceOverlapResult(
      overlaps: true,
      overlapStart: start,
      overlapEnd: end,
    );
  }

  static DateTime _effectiveEnd(
    EventCheckIn presence,
    EventCheckIn other,
    DateTime? referenceTime,
  ) {
    if (presence.checkedOutAt case final checkedOutAt?) return checkedOutAt;
    if (referenceTime != null) return referenceTime;
    return other.checkedOutAt ?? presence.checkedInAt;
  }
}
