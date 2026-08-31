import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/identity/current_user_provider.dart';
import '../../../core/auth/auth_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/storage/storage_providers.dart';
import '../domain/local_notification.dart';
import '../domain/notification_repository.dart';
import 'local_notification_repository.dart';
import 'supabase_notification_repository.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => ref.watch(authRepositoryProvider) == null
      ? LocalNotificationRepository(
          ref.watch(localStorageProvider),
          onChanged: () {},
        )
      : SupabaseNotificationRepository(Supabase.instance.client),
);
final notificationsProvider = FutureProvider<List<LocalNotification>>((
  ref,
) async {
  final userId = await ref.watch(currentUserIdProvider.future);
  return ref.watch(notificationRepositoryProvider).getForUser(userId);
});
final unreadNotificationCountProvider = Provider<int>(
  (ref) => (ref.watch(notificationsProvider).value ?? [])
      .where((n) => !n.read)
      .length,
);
