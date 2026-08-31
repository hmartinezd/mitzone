import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/identity/identity_providers.dart';
import '../../../core/identity/current_user_provider.dart';
import '../../../core/auth/auth_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/storage/storage_providers.dart';
import '../domain/local_notification.dart';
import '../domain/notification_repository.dart';
import 'local_notification_repository.dart';
import 'supabase_notification_repository.dart';

final notificationVersionProvider = StateProvider<int>((ref) => 0);
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) => ref.watch(authRepositoryProvider) == null
    ? LocalNotificationRepository(
    ref.watch(localStorageProvider),
    onChanged: () => ref.read(notificationVersionProvider.notifier).state++,
  )
    : SupabaseNotificationRepository(Supabase.instance.client));
final notificationsProvider = FutureProvider<List<LocalNotification>>((ref) {
  ref.watch(notificationVersionProvider);
  return ref.watch(notificationRepositoryProvider).getForUser(
    ref.watch(productionModeProvider) ? ref.watch(currentUserIdProvider).value ?? '' : ref.watch(mockIdentityRepositoryProvider).currentUser.id,
  );
});
final unreadNotificationCountProvider = Provider<int>(
  (ref) => (ref.watch(notificationsProvider).value ?? [])
      .where((n) => !n.read)
      .length,
);
