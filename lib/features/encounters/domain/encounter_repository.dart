import 'encounter.dart';
import 'presence_evidence.dart';

abstract interface class EncounterRepository {
  Future<List<Encounter>> getEncountersForUser(String userId);

  /// Processes one newly recorded presence without exposing other users'
  /// evidence to the caller. Implementations must be idempotent.
  Future<List<Encounter>> processEvidence(PresenceEvidence evidence, {
    required String actorUserId,
  });
}
