import 'presence_evidence.dart';

abstract interface class PresenceRepository {
  Future<DateTime> recordForegroundPresence({required double latitude, required double longitude}) async => throw UnimplementedError();
  Future<void> stopForegroundPresence() async {}
  Future<PresenceEvidence?> getEvidence({
    required String userId,
    required String contextId,
  });
  Future<PresenceEvidence> recordEvidence(
    PresenceEvidence evidence, {
    required String actorUserId,
  });
  Future<List<PresenceEvidence>> getEvidenceForUser(String userId);
  Future<void> revokeEvidence({
    required String evidenceId,
    required String actorUserId,
  });
}
