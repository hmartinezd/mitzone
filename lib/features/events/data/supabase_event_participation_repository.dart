import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/event_participation_repository.dart';

class SupabaseEventParticipationRepository
    implements EventParticipationRepository {
  const SupabaseEventParticipationRepository(this._client);

  final SupabaseClient _client;
  static const _table = 'event_participation';

  @override
  Future<Set<String>> getJoinedEventIds(String identityId) async {
    final rows = await _client
        .from(_table)
        .select('event_id')
        .eq('user_id', identityId);
    return rows
        .whereType<Map>()
        .map((row) => row['event_id'])
        .whereType<String>()
        .toSet();
  }

  @override
  Future<bool> isJoined({required String identityId, required String eventId}) async {
    final rows = await _client
        .from(_table)
        .select('event_id')
        .eq('user_id', identityId)
        .eq('event_id', eventId.trim())
        .limit(1);
    return rows.isNotEmpty;
  }

  @override
  Future<void> join({required String identityId, required String eventId}) async {
    final id = eventId.trim();
    if (id.isEmpty) return;
    await _client.from(_table).upsert({
      'user_id': identityId,
      'event_id': id,
      'joined_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'user_id,event_id');
  }

  @override
  Future<void> leave({required String identityId, required String eventId}) async {
    final id = eventId.trim();
    if (id.isEmpty) return;
    await _client.from(_table).delete().eq('user_id', identityId).eq('event_id', id);
  }
}
