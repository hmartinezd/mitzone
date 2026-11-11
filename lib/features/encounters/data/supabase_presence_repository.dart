import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/presence_evidence.dart';
import '../domain/presence_repository.dart';
import 'foreground_presence_service.dart';

class SupabasePresenceRepository
    implements
        PresenceRepository,
        ForegroundPresenceGateway,
        ForegroundPresenceRefreshGateway {
  SupabasePresenceRepository(this.client);
  final SupabaseClient client;
  String? _foregroundEvidenceId;
  String? _foregroundOwnerId;

  @override
  Future<void> stopForegroundPresence() async {
    await client.rpc('stop_foreground_presence');
    _foregroundEvidenceId = null;
    _foregroundOwnerId = null;
  }

  @override
  Future<DateTime> recordForegroundPresence({
    required double latitude,
    required double longitude,
  }) async {
    final subject = client.auth.currentUser?.id;
    if (subject == null) throw StateError('Authentication required');
    final rows =
        await client.rpc(
              'record_foreground_presence',
              params: {'p_latitude': latitude, 'p_longitude': longitude},
            )
            as List;
    if (rows.isEmpty) throw StateError('Presence unavailable');
    final row = rows.first as Map<String, dynamic>;
    final evidence = PresenceEvidence(
      id: row['evidence_id'] as String,
      subjectUserId: subject,
      contextId: row['context_id'] as String,
      observedStart: DateTime.parse(row['observed_start'] as String).toUtc(),
      observedEnd: DateTime.parse(row['observed_end'] as String).toUtc(),
      source: PresenceEvidenceSource.geolocation,
      consentScope: 'foreground-explicit',
      expiresAt: DateTime.parse(row['expires_at'] as String).toUtc(),
    );
    if (client.auth.currentUser?.id != subject) {
      throw StateError('Presence account changed');
    }
    _foregroundEvidenceId = evidence.id;
    _foregroundOwnerId = subject;
    return evidence.expiresAt!;
  }

  @override
  Future<DateTime> refreshForegroundPresence({
    required double latitude,
    required double longitude,
  }) async {
    final subject = client.auth.currentUser?.id;
    final evidenceId = _foregroundEvidenceId;
    if (subject == null ||
        subject != _foregroundOwnerId ||
        evidenceId == null) {
      throw StateError('No active presence lease for this account');
    }
    final rows =
        await client.rpc(
              'refresh_foreground_presence',
              params: {
                'p_evidence_id': evidenceId,
                'p_latitude': latitude,
                'p_longitude': longitude,
              },
            )
            as List;
    if (rows.isEmpty || client.auth.currentUser?.id != subject) {
      throw StateError('Presence unavailable');
    }
    final row = rows.first as Map<String, dynamic>;
    if (row['evidence_id'] != evidenceId) {
      throw StateError('Presence lease changed');
    }
    return DateTime.parse(row['expires_at'] as String).toUtc();
  }

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
    if (client.auth.currentUser?.id != id) {
      throw StateError('Presence ownership mismatch');
    }
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
    if (e.subjectUserId != actorUserId) {
      throw StateError('Presence ownership mismatch');
    }
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
