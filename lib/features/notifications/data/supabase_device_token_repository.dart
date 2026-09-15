import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/domain_error.dart';
import '../domain/device_token.dart';
import '../domain/device_token_repository.dart';

class SupabaseDeviceTokenRepository implements DeviceTokenRepository {
  const SupabaseDeviceTokenRepository(this.client);
  final SupabaseClient client;

  String _owner(String userId) {
    final current = client.auth.currentUser?.id;
    if (current == null || current != userId) {
      throw const DomainError(DomainErrorCode.unauthorized, 'Authentication required.');
    }
    return current;
  }

  @override
  Future<void> register(String userId, DeviceToken token) async {
    final owner = _owner(userId);
    final now = DateTime.now().toUtc().toIso8601String();
    await client.from('device_tokens').upsert({
      'user_id': owner, 'token': token.token,
      'platform': token.platform.name, 'updated_at': now, 'last_seen_at': now,
    }, onConflict: 'token');
  }

  @override
  Future<void> remove(String userId, String token) async {
    final owner = _owner(userId);
    await client.from('device_tokens').delete().eq('user_id', owner).eq('token', token);
  }
}
