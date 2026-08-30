import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/identity/identity_providers.dart';
import '../../../core/storage/storage_providers.dart';
import '../domain/local_notification.dart';
import 'local_notification_repository.dart';
final notificationRepositoryProvider = Provider((ref) => LocalNotificationRepository(ref.watch(localStorageProvider)));
final notificationsProvider = FutureProvider<List<LocalNotification>>((ref) => ref.watch(notificationRepositoryProvider).getForUser(ref.watch(mockIdentityRepositoryProvider).currentUser.id));
final unreadNotificationCountProvider = Provider<int>((ref) => (ref.watch(notificationsProvider).value ?? []).where((n) => !n.read).length);
