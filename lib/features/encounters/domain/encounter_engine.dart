import '../../events/domain/event_check_in.dart';
import '../../events/domain/presence_overlap.dart';
import 'encounter.dart';

class EncounterEngine {
  const EncounterEngine(this._presences);
  final List<EventCheckIn> _presences;

  List<Encounter> forUser(String userId, {DateTime? referenceTime}) {
    final mine = _presences.where((p) => p.identityId == userId);
    final result = <Encounter>[];
    for (final a in mine) {
      for (final b in _presences) {
        if (b.identityId == userId || b.eventId != a.eventId) continue;
        final overlap = PresenceOverlap.calculate(a, b, referenceTime: referenceTime);
        if (!overlap.overlaps) continue;
        result.add(Encounter(id: '${userId}_${b.identityId}_${a.eventId}', currentUserId: userId, otherUserId: b.identityId, eventId: a.eventId, overlapStart: overlap.overlapStart!, overlapEnd: overlap.overlapEnd!));
      }
    }
    result.sort((a, b) => b.overlapStart.compareTo(a.overlapStart));
    return result;
  }
}
