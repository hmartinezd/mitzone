import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/identity/identity_providers.dart';
import '../../../core/storage/storage_providers.dart';
import '../domain/local_notification.dart';
import 'local_notification_repository.dart';

final notificationVersionProvider = StateProvider<int>((ref) => 0);
final notificationRepositoryProvider = Provider(
  (ref) => LocalNotificationRepository(
    ref.watch(localStorageProvider),
    onChanged: () => ref.read(notificationVersionProvider.notifier).state++,
  ),
);
final notificationsProvider = FutureProvider<List<LocalNotification>>((ref) {
  ref.watch(notificationVersionProvider);
  return ref
      .watch(notificationRepositoryProvider)
      .getForUser(ref.watch(mockIdentityRepositoryProvider).currentUser.id);
});
final unreadNotificationCountProvider = Provider<int>(
  (ref) => (ref.watch(notificationsProvider).value ?? [])
      .where((n) => !n.read)
      .length,
);
