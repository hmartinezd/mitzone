import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/presence_evidence.dart';
import '../domain/presence_repository.dart';

class SupabasePresenceRepository implements PresenceRepository {
  SupabasePresenceRepository(this.client);
  final SupabaseClient client;
  Map<String, dynamic> row(PresenceEvidence e) => {
    'id': e.id,
    'subject_user_id': e.subjectUserId,
    'context_id': e.contextId,
    'observed_start': e.observedStart.toIso8601String(),
    'observed_end': e.observedEnd.toIso8601String(),
    'source': e.source.name,
    'confidence': e.confidence,
    'consent_scope': e.consentScope,
    'expires_at': e.expiresAt?.toIso8601String(),
  };
  PresenceEvidence parse(Map<String, dynamic> r) => PresenceEvidence(
    id: r['id'],
    subjectUserId: r['subject_user_id'],
    contextId: r['context_id'],
    observedStart: DateTime.parse(r['observed_start']),
    observedEnd: DateTime.parse(r['observed_end']),
    source: PresenceEvidenceSource.values.byName(r['source']),
    confidence: (r['confidence'] as num?)?.toDouble(),
    consentScope: r['consent_scope'],
    expiresAt: r['expires_at'] == null ? null : DateTime.parse(r['expires_at']),
  );
  void owner(String id) {
    if (client.auth.currentUser?.id != id)
      throw StateError('Presence ownership mismatch');
  }

  @override
  Future<PresenceEvidence?> getEvidence({
    required String userId,
    required String contextId,
  }) async {
    owner(userId);
    final r = await client
        .from('presence_evidence')
        .select()
        .eq('subject_user_id', userId)
        .eq('context_id', contextId)
        .maybeSingle();
    return r == null ? null : parse(r);
  }

  @override
  Future<List<PresenceEvidence>> getEvidenceForUser(String userId) async {
    owner(userId);
    final rows = await client
        .from('presence_evidence')
        .select()
        .eq('subject_user_id', userId);
    return rows.map<PresenceEvidence>((r) => parse(r)).toList();
  }

  @override
  Future<PresenceEvidence> recordEvidence(
    PresenceEvidence e, {
    required String actorUserId,
  }) async {
    owner(actorUserId);
    if (e.subjectUserId != actorUserId)
      throw StateError('Presence ownership mismatch');
    final r = await client
        .from('presence_evidence')
        .upsert(row(e), onConflict: 'subject_user_id,context_id')
        .select()
        .single();
    return parse(r);
  }

  @override
  Future<void> revokeEvidence({
    required String evidenceId,
    required String actorUserId,
  }) async {
    owner(actorUserId);
    await client
        .from('presence_evidence')
        .delete()
        .eq('id', evidenceId)
        .eq('subject_user_id', actorUserId);
  }
}
