import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/block_repository.dart';

class SupabaseBlockRepository implements BlockRepository {
  SupabaseBlockRepository(this.client);
  final SupabaseClient client;

  void _own(String id) {
    if (client.auth.currentUser?.id != id) {
      throw StateError('Block ownership mismatch');
    }
  }

  @override
  Future<bool> isBlocked(String blocker, String blocked) async {
    final row = await client.from('blocks').select('blocked_user_id').match({
      'blocker_user_id': blocker,
      'blocked_user_id': blocked,
    }).maybeSingle();
    return row != null;
  }

  @override
  Future<void> block({required String blockerUserId, required String blockedUserId}) async {
    _own(blockerUserId);
    if (blockerUserId == blockedUserId) throw ArgumentError('Cannot block yourself');
    await client.from('blocks').upsert({
      'blocker_user_id': blockerUserId,
      'blocked_user_id': blockedUserId,
    }, onConflict: 'blocker_user_id,blocked_user_id');
  }

  @override
  Future<void> unblock({required String blockerUserId, required String blockedUserId}) async {
    _own(blockerUserId);
    await client.from('blocks').delete().match({
      'blocker_user_id': blockerUserId,
      'blocked_user_id': blockedUserId,
    });
  }

  @override
  Future<List<String>> getBlocked(String blockerUserId) async {
    _own(blockerUserId);
    final rows = await client.from('blocks').select('blocked_user_id').eq('blocker_user_id', blockerUserId);
    return rows.map<String>((row) => row['blocked_user_id'] as String).toList();
  }
}
