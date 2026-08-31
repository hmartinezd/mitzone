import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/identity/current_user_provider.dart';
import '../../chat/data/chat_providers.dart';
import '../data/notification_providers.dart';
import '../domain/local_notification.dart';

class NotificationCenterScreen extends ConsumerWidget {
  const NotificationCenterScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identity = ref.watch(currentUserIdProvider);
    if (identity.isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (identity.hasError)
      return const Scaffold(
        body: Center(child: Text('Notifications unavailable')),
      );
    final user = identity.requireValue;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () =>
                ref.read(notificationRepositoryProvider).markAllRead(user),
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: ref
          .watch(notificationsProvider)
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) =>
                const Center(child: Text('Notifications unavailable')),
            data: (items) => items.isEmpty
                ? const Center(child: Text('No notifications yet.'))
                : ListView(
                    children: items
                        .map(
                          (n) => ListTile(
                            title: Text(_title(n.type)),
                            subtitle: Text(n.timestamp.toLocal().toString()),
                            leading: Icon(
                              n.read
                                  ? Icons.notifications_none
                                  : Icons.notifications_active,
                            ),
                            onTap: () => _open(context, ref, n, user),
                          ),
                        )
                        .toList(),
                  ),
          ),
    );
  }

  Future<void> _open(
    BuildContext context,
    WidgetRef ref,
    LocalNotification n,
    String user,
  ) async {
    await ref.read(notificationRepositoryProvider).markRead(user, n.id);
    if (!context.mounted) return;
    if (n.type == LocalNotificationType.newMessage) {
      try {
        await ref
            .read(chatRepositoryProvider)
            .getMessages(conversationId: n.entityId, userId: user);
      } catch (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This conversation is no longer available.'),
          ),
        );
        return;
      }
    }
    context.push(n.destination);
  }

  static String _title(LocalNotificationType type) => switch (type) {
    LocalNotificationType.connectionRequest => 'New connection request',
    LocalNotificationType.connectionAccepted => 'Connection accepted',
    LocalNotificationType.newMessage => 'New message',
  };
}
