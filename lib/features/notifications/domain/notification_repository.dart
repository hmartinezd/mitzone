import 'local_notification.dart';

abstract interface class NotificationRepository {
  Future<List<LocalNotification>> getForUser(String userId);
  Future<void> add(LocalNotification notification);
  Future<void> markRead(String userId, String id);
  Future<void> markAllRead(String userId);
}
