import 'package:flutter_test/flutter_test.dart';
import 'package:mitzone/core/storage/local_storage.dart';
import 'package:mitzone/features/notifications/data/local_notification_repository.dart';
import 'package:mitzone/features/notifications/domain/local_notification.dart';

void main() {
  test('persists per identity and prevents duplicate notifications', () async {
    final storage = MemoryStorage();
    final repo = LocalNotificationRepository(storage);
    const first = LocalNotification(id: 'request-1', type: LocalNotificationType.connectionRequest, userId: 'jose', timestamp: DateTime(2026, 1, 1), entityId: 'r1', destination: '/app/matches');
    await repo.add(first);
    await repo.add(first);
    await repo.add(const LocalNotification(id: 'request-2', type: LocalNotificationType.connectionRequest, userId: 'sofia', timestamp: DateTime(2026, 1, 2), entityId: 'r2', destination: '/app/matches'));
    expect((await repo.getForUser('jose')), hasLength(1));
    expect((await repo.getForUser('sofia')), hasLength(1));
    expect((await repo.getForUser('jose')).single.read, isFalse);
    await repo.markRead('jose', 'request-1');
    expect((await repo.getForUser('jose')).single.read, isTrue);
    final reloaded = LocalNotificationRepository(storage);
    expect((await reloaded.getForUser('jose')).single.read, isTrue);
  });
}

class MemoryStorage implements LocalStorage {
  final values = <String, String>{};
  @override Future<String?> getString(String key) async => values[key];
  @override Future<void> setString(String key, String value) async => values[key] = value;
  @override Future<bool?> getBool(String key) async => null;
  @override Future<void> setBool(String key, bool value) async {}
}
