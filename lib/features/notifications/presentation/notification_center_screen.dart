import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/identity/identity_providers.dart';
import '../data/notification_providers.dart';

class NotificationCenterScreen extends ConsumerWidget {
  const NotificationCenterScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationsProvider);
    final user = ref.watch(mockIdentityRepositoryProvider).currentUser.id;
    return Scaffold(appBar: AppBar(title: const Text('Notifications'), actions: [TextButton(onPressed: () async { await ref.read(notificationRepositoryProvider).markAllRead(user); ref.invalidate(notificationsProvider); }, child: const Text('Mark all read'))]), body: state.when(loading: () => const Center(child: CircularProgressIndicator()), error: (_, _) => const Center(child: Text('Notifications unavailable')), data: (items) => items.isEmpty ? const Center(child: Text('No notifications yet.')) : ListView(children: items.map((n) => ListTile(title: Text(_title(n.type)), subtitle: Text(n.timestamp.toLocal().toString()), leading: Icon(n.read ? Icons.notifications_none : Icons.notifications_active), onTap: () async { await ref.read(notificationRepositoryProvider).markRead(user, n.id); ref.invalidate(notificationsProvider); if (context.mounted) context.push(n.destination); })).toList()));
  }
  static String _title(type) => switch (type.name) { 'connectionRequest' => 'New connection request', 'connectionAccepted' => 'Connection accepted', _ => 'New message' };
}
