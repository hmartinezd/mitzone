import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/encounter.dart';
import '../domain/encounter_repository.dart';
import '../domain/presence_evidence.dart';

class SupabaseEncounterRepository implements EncounterRepository {
  SupabaseEncounterRepository(this.client);
  final SupabaseClient client;

  void _own(String userId) {
    if (client.auth.currentUser?.id != userId) {
      throw StateError('Encounter ownership mismatch');
    }
  }

  Encounter _parse(Map<String, dynamic> row, String userId) => Encounter(
        id: row['id'] as String,
        currentUserId: userId,
        otherUserId: row['other_user_id'] as String,
        eventId: row['context_id'] as String,
        overlapStart: DateTime.parse(row['overlap_start'] as String),
        overlapEnd: DateTime.parse(row['overlap_end'] as String),
      );

  @override
  Future<List<Encounter>> getEncountersForUser(String userId) async {
    _own(userId);
    final rows = await client
        .from('encounters')
        .select()
        .or('user_a.eq.$userId,user_b.eq.$userId')
        .order('overlap_start', ascending: false);
    return rows.map<Encounter>((row) {
      final other = row['user_a'] == userId ? row['user_b'] : row['user_a'];
      return _parse({...row, 'other_user_id': other}, userId);
    }).toList();
  }

  @override
  Future<List<Encounter>> processEvidence(PresenceEvidence evidence, {
    required String actorUserId,
  }) async {
    _own(actorUserId);
    if (evidence.subjectUserId != actorUserId) {
      throw StateError('Encounter ownership mismatch');
    }
    await client.rpc('process_presence_evidence', params: {
      'p_evidence_id': evidence.id,
    });
    return getEncountersForUser(actorUserId);
  }
}
