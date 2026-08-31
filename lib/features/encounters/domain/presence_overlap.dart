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
    if (a.subjectUserId == b.subjectUserId || a.contextId != b.contextId) {
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
}
