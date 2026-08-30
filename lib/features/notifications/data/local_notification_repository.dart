import 'dart:convert';
import '../../../core/storage/local_storage.dart';
import '../domain/local_notification.dart';
import '../domain/notification_repository.dart';

class LocalNotificationRepository implements NotificationRepository {
  const LocalNotificationRepository(this.storage, {this.onChanged});
  final LocalStorage storage;
  final void Function()? onChanged;
  String _key(String userId) => 'local_notifications.v1.$userId';
  Future<List<LocalNotification>> _read(String userId) async {
    try {
      final raw = jsonDecode(await storage.getString(_key(userId)) ?? '[]');
      if (raw is! List) return [];
      return raw
          .whereType<Map>()
          .map(
            (x) => LocalNotification(
              id: x['id'] as String,
              type: LocalNotificationType.values.byName(x['type'] as String),
              userId: x['user'] as String,
              timestamp: DateTime.parse(x['time'] as String),
              entityId: x['entity'] as String,
              destination: x['destination'] as String,
              read: x['read'] == true,
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _write(String userId, List<LocalNotification> items) =>
      storage.setString(
        _key(userId),
        jsonEncode(
          items
              .map(
                (n) => {
                  'id': n.id,
                  'type': n.type.name,
                  'user': n.userId,
                  'time': n.timestamp.toIso8601String(),
                  'entity': n.entityId,
                  'destination': n.destination,
                  'read': n.read,
                },
              )
              .toList(),
        ),
      );
  @override
  Future<List<LocalNotification>> getForUser(String userId) async {
    final items = await _read(userId);
    items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return items;
  }

  @override
  Future<void> add(LocalNotification n) async {
    final items = await _read(n.userId);
    if (items.any((x) => x.id == n.id)) return;
    items.add(n);
    await _write(n.userId, items);
    onChanged?.call();
  }

  @override
  Future<void> markRead(String userId, String id) async {
    await _write(
      userId,
      (await _read(
        userId,
      )).map((n) => n.id == id ? n.copyWith(read: true) : n).toList(),
    );
    onChanged?.call();
  }

  @override
  Future<void> markAllRead(String userId) async {
    await _write(
      userId,
      (await _read(userId)).map((n) => n.copyWith(read: true)).toList(),
    );
    onChanged?.call();
  }
}
