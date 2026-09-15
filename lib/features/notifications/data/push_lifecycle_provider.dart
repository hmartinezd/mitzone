import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/auth_providers.dart';
import 'device_token_providers.dart';
import 'push_notification_service.dart';
import 'notification_providers.dart';

final pushLifecycleProvider = Provider<void>((ref) {
  final session = ref.watch(authSessionProvider).valueOrNull;
  final repository = ref.watch(deviceTokenRepositoryProvider);
  if (session == null || repository == null) return;
  final service = PushNotificationService(repository, session.user.id);
  service.onForeground = () => ref.invalidate(notificationsProvider);
  service.start();
  ref.onDispose(service.dispose);
});
