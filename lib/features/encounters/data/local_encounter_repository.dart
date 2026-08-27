import '../../events/domain/event_check_in.dart';
import 'package:mitzone/features/encounters/domain/encounter.dart';
import '../domain/encounter_engine.dart';
import '../domain/encounter_repository.dart';

class LocalEncounterRepository implements EncounterRepository {
  const LocalEncounterRepository({required this.currentUserPresence, required this.otherUserPresence});
  final List<EventCheckIn> currentUserPresence;
  final List<EventCheckIn> otherUserPresence;
  @override
  Future<List<Encounter>> getEncountersForUser(String userId) async =>
      EncounterEngine([
        ...currentUserPresence.where((p) => p.identityId == userId),
        ...otherUserPresence.where((p) => p.identityId != userId),
      ]).forUser(userId);
}
