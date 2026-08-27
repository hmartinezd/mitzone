import '../../events/data/mock_event_attendees.dart';
import '../domain/encounter.dart';
import '../domain/encounter_engine.dart';
import '../domain/encounter_repository.dart';

class LocalEncounterRepository implements EncounterRepository {
  const LocalEncounterRepository();
  @override
  Future<List<Encounter>> getEncountersForUser(String userId) async =>
      EncounterEngine(mockEventAttendees).forUser(userId);
}
