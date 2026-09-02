import 'presence_evidence.dart';

/// The smallest overlap that is meaningful for the initial event/check-in
/// model. This is domain policy, not a UI or repository concern.
const initialMeaningfulPresenceOverlap = Duration(minutes: 5);

class PresenceOverlap {
  const PresenceOverlap({required this.start, required this.end});
  final DateTime start;
  final DateTime end;
  Duration get duration => end.difference(start);

  static PresenceOverlap? between(
    PresenceEvidence a,
    PresenceEvidence b, {
    Duration minimum = initialMeaningfulPresenceOverlap,
  }) {
    if (a.subjectUserId == b.subjectUserId || !contextsCompatible(a.contextId, b.contextId)) {
      return null;
    }
    final start = a.observedStart.isAfter(b.observedStart)
        ? a.observedStart
        : b.observedStart;
    final end = a.observedEnd.isBefore(b.observedEnd)
        ? a.observedEnd
        : b.observedEnd;
    if (end.difference(start) < minimum) return null;
    return PresenceOverlap(start: start, end: end);
  }

  /// Geolocation cells include only their immediate 8 neighbors; event contexts stay exact.
  static bool contextsCompatible(String a, String b) {
    if (a == b) return true;
    if (!a.startsWith('cell:') || !b.startsWith('cell:')) return false;
    final pa = a.substring(5).split(':');
    final pb = b.substring(5).split(':');
    if (pa.length != 2 || pb.length != 2) return false;
    final ax = int.tryParse(pa[0]), ay = int.tryParse(pa[1]);
    final bx = int.tryParse(pb[0]), by = int.tryParse(pb[1]);
    return ax != null && ay != null && bx != null && by != null &&
        (ax - bx).abs() <= 1 && (ay - by).abs() <= 1;
  }
}
