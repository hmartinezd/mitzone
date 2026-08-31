import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/local_notification.dart';
import '../domain/notification_repository.dart';

class SupabaseNotificationRepository implements NotificationRepository {
  const SupabaseNotificationRepository(this.client);
  final SupabaseClient client;
  LocalNotification _map(Map<String, dynamic> row) => LocalNotification(id: row['id'] as String, type: LocalNotificationType.values.byName(row['type'] as String), userId: row['recipient_user_id'] as String, timestamp: DateTime.parse(row['created_at'] as String), entityId: row['entity_id'] as String? ?? '', destination: row['destination'] as String? ?? '', read: row['read_at'] != null);
  @override Future<List<LocalNotification>> getForUser(String userId) async { final rows = await client.from('notifications').select().eq('recipient_user_id', userId).order('created_at', ascending: false); return [for (final row in rows) _map(row)]; }
  @override Future<void> add(LocalNotification notification) async { throw UnsupportedError('Production notifications are created by secured server operations.'); }
  @override Future<void> markRead(String userId, String id) async { await client.from('notifications').update({'read_at': DateTime.now().toUtc().toIso8601String()}).eq('id', id).eq('recipient_user_id', userId); }
  @override Future<void> markAllRead(String userId) async { await client.from('notifications').update({'read_at': DateTime.now().toUtc().toIso8601String()}).eq('recipient_user_id', userId).isFilter('read_at', null); }
}
