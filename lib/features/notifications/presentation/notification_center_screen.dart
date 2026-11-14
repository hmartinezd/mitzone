import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/identity/current_user_provider.dart';
import '../../chat/data/chat_providers.dart';
import '../../profile/data/public_peer_profiles.dart';
import '../data/notification_providers.dart';
import '../domain/local_notification.dart';

class NotificationCenterScreen extends ConsumerStatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  ConsumerState<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState
    extends ConsumerState<NotificationCenterScreen> {
  bool _markingAll = false;
  final Set<String> _opening = {};

  @override
  Widget build(BuildContext context) {
    final identity = ref.watch(currentUserIdProvider);
    final notifications = ref.watch(notificationsProvider);
    final unread =
        !notifications.isLoading &&
        !notifications.hasError &&
        (notifications.value?.any((item) => !item.read) ?? false);
    final profiles = ref.watch(
      publicPeerProfilesProvider(
        publicPeerIdsKey(
          (notifications.value ?? const <LocalNotification>[])
              .map((n) => n.actorUserId)
              .whereType<String>(),
        ),
      ),
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (unread && identity.hasValue)
            TextButton(
              onPressed: _markingAll
                  ? null
                  : () => _markAllRead(identity.requireValue),
              child: Text(_markingAll ? 'Marking…' : 'Mark all read'),
            ),
        ],
      ),
      body: identity.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _error(() {
          ref.invalidate(currentUserIdProvider);
          ref.invalidate(notificationsProvider);
        }),
        data: (user) => notifications.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => _error(() => ref.invalidate(notificationsProvider)),
          data: (items) => items.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No notifications yet. Connection requests and new messages will appear here.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final n = items[index];
                    final opening = _opening.contains(n.id);
                    final stamp = _timestamp(context, n.timestamp);
                    return Semantics(
                      label: '${n.read ? 'Read' : 'Unread'} notification',
                      child: ListTile(
                        title: Text(_title(n.type)),
                        isThreeLine: n.actorUserId != null,
                        subtitle: Text(
                          [
                            if (n.actorUserId != null)
                              peerProfileLabel(profiles, n.actorUserId!),
                            '$stamp${n.read ? '' : ' · Unread'}',
                          ].join('\n'),
                        ),
                        leading: Icon(
                          n.read
                              ? Icons.notifications_none
                              : Icons.notifications_active,
                        ),
                        trailing: opening
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.chevron_right),
                        onTap: opening ? null : () => _open(n, user),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }

  Widget _error(VoidCallback retry) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Notifications are unavailable right now.'),
          TextButton(onPressed: retry, child: const Text('Try again')),
        ],
      ),
    ),
  );

  Future<void> _markAllRead(String user) async {
    if (_markingAll) return;
    setState(() => _markingAll = true);
    try {
      await ref.read(notificationRepositoryProvider).markAllRead(user);
      if (!mounted) return;
      ref.invalidate(notificationsProvider);
      _feedback('All notifications marked as read.');
    } catch (_) {
      if (mounted) {
        _feedback('Could not mark notifications as read. Try again.');
      }
    } finally {
      if (mounted) setState(() => _markingAll = false);
    }
  }

  Future<void> _open(LocalNotification n, String user) async {
    if (_opening.contains(n.id)) return;
    setState(() => _opening.add(n.id));
    try {
      if (n.type == LocalNotificationType.newMessage) {
        try {
          await ref
              .read(chatRepositoryProvider)
              .getMessages(conversationId: n.entityId, userId: user);
        } catch (_) {
          if (mounted) _feedback('This conversation is no longer available.');
          return;
        }
      }
      try {
        await ref.read(notificationRepositoryProvider).markRead(user, n.id);
        if (!mounted) return;
        ref.invalidate(notificationsProvider);
      } catch (_) {
        // Read-state bookkeeping must not silently swallow a valid navigation.
        if (!mounted) return;
        _feedback(
          'Opened notification, but could not mark it as read. Try again later.',
        );
      }
      if (mounted) context.push(n.destination);
    } finally {
      if (mounted) setState(() => _opening.remove(n.id));
    }
  }

  void _feedback(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  static String _timestamp(BuildContext context, DateTime timestamp) {
    final local = timestamp.toLocal();
    final material = MaterialLocalizations.of(context);
    final date = material.formatMediumDate(local);
    final time = material.formatTimeOfDay(
      TimeOfDay.fromDateTime(local),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
    return '$date · $time';
  }

  static String _title(LocalNotificationType type) => switch (type) {
    LocalNotificationType.connectionRequest => 'New connection request',
    LocalNotificationType.connectionAccepted => 'Connection accepted',
    LocalNotificationType.newMessage => 'New message',
  };
}
