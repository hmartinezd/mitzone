import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/local_notification.dart';
import '../domain/notification_repository.dart';
import '../../../core/errors/domain_error.dart';

class SupabaseNotificationRepository implements NotificationRepository {
  const SupabaseNotificationRepository(this.client);
  final SupabaseClient client;
  LocalNotification _map(Map<String, dynamic> row) => LocalNotification(
    id: row['id'] as String,
    type: LocalNotificationType.values.byName(row['type'] as String),
    userId: row['recipient_user_id'] as String,
    timestamp: DateTime.parse(row['created_at'] as String),
    entityId: row['entity_id'] as String? ?? '',
    destination: row['destination'] as String? ?? '',
    read: row['read_at'] != null,
  );
  String _requireOwner(String requested) {
    final id = client.auth.currentUser?.id;
    if (id == null)
      throw const DomainError(
        DomainErrorCode.unauthorized,
        'Authentication required.',
      );
    if (id != requested)
      throw const DomainError(
        DomainErrorCode.unauthorized,
        'Notification ownership mismatch.',
      );
    return id;
  }

  @override
  Future<List<LocalNotification>> getForUser(String userId) async {
    final id = _requireOwner(userId);
    final rows = await client
        .from('notifications')
        .select()
        .eq('recipient_user_id', id)
        .order('created_at', ascending: false);
    return [for (final row in rows) _map(row)];
  }

  @override
  Future<void> add(LocalNotification notification) async {
    throw UnsupportedError(
      'Production notifications are created by secured server operations.',
    );
  }

  @override
  Future<void> markRead(String userId, String id) async {
    final owner = _requireOwner(userId);
    await client
        .from('notifications')
        .update({'read_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', id)
        .eq('recipient_user_id', owner);
  }

  @override
  Future<void> markAllRead(String userId) async {
    final owner = _requireOwner(userId);
    await client
        .from('notifications')
        .update({'read_at': DateTime.now().toUtc().toIso8601String()})
        .eq('recipient_user_id', owner)
        .isFilter('read_at', null);
  }
}
