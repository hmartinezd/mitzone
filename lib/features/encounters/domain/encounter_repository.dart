import 'encounter.dart';

abstract interface class EncounterRepository {
  Future<List<Encounter>> getEncountersForUser(String userId);
}
