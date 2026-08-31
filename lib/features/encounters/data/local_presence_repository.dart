import 'dart:convert';
import '../../../core/storage/local_storage.dart';
import '../domain/presence_evidence.dart';
import '../domain/presence_repository.dart';

class LocalPresenceRepository implements PresenceRepository {
  const LocalPresenceRepository(this.storage);
  final LocalStorage storage;
  String key(String id) => 'local_presence_evidence.v1.$id';
  @override
  Future<List<PresenceEvidence>> getEvidenceForUser(String id) async => [];
  @override
  Future<PresenceEvidence?> getEvidence({
    required String userId,
    required String contextId,
  }) async => (await getEvidenceForUser(
    userId,
  )).where((e) => e.contextId == contextId).firstOrNull;
  @override
  Future<PresenceEvidence> recordEvidence(
    PresenceEvidence evidence, {
    required String actorUserId,
  }) async {
    if (evidence.subjectUserId != actorUserId) {
      throw StateError('Presence ownership mismatch');
    }
    final existing = await getEvidence(
      userId: actorUserId,
      contextId: evidence.contextId,
    );
    if (existing != null) return existing;
    await storage.setString(
      key(evidence.id),
      jsonEncode({
        'id': evidence.id,
        'user': evidence.subjectUserId,
        'context': evidence.contextId,
      }),
    );
    return evidence;
  }

  @override
  Future<void> revokeEvidence({
    required String evidenceId,
    required String actorUserId,
  }) async {}
}
