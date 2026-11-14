import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/identity/identity_providers.dart';
import '../../../app/router/app_routes.dart';
import '../../../core/auth/auth_providers.dart';
import '../../../core/identity/current_user_provider.dart';
import '../../connections/data/connection_providers.dart';
import '../../profile/presentation/widgets/profile_avatar.dart';
import '../data/chat_providers.dart';
import '../../profile/data/public_peer_profiles.dart';
import '../domain/chat_models.dart';
import '../../notifications/data/notification_providers.dart';

class ChatScreen extends ConsumerWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversations = ref.watch(chatConversationsProvider);
    final connections = ref.watch(connectionsProvider);
    final production = ref.watch(productionModeProvider);
    final identity = production
        ? null
        : ref.watch(mockIdentityRepositoryProvider);
    final currentUserId = production
        ? (ref.watch(currentUserIdProvider).value ?? '')
        : identity!.currentUser.id;
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(AppRoutes.home),
        ),
        title: const Text('Chat'),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => context.push('/app/notifications'),
            icon: Badge(
              isLabelVisible: ref.watch(unreadNotificationCountProvider) > 0,
              label: Text('${ref.watch(unreadNotificationCountProvider)}'),
              child: const Icon(Icons.notifications_outlined),
            ),
          ),
        ],
      ),
      body: conversations.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _RetryState(
          message: 'Your conversations are unavailable right now.',
          onRetry: () => ref.invalidate(chatConversationsProvider),
        ),
        data: (items) => connections.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => _RetryState(
            message: 'Your connections are unavailable right now.',
            onRetry: () => ref.invalidate(connectionsProvider),
          ),
          data: (activeConnections) {
            final ordered = [...activeConnections]
              ..sort((a, b) {
                final aConversation = _forConnection(items, a.id);
                final bConversation = _forConnection(items, b.id);
                final aTime = aConversation?.lastMessageAt;
                final bTime = bConversation?.lastMessageAt;
                if (aTime == null && bTime == null) return a.id.compareTo(b.id);
                if (aTime == null) return 1;
                if (bTime == null) return -1;
                return bTime.compareTo(aTime);
              });
            if (ordered.isEmpty) {
              return _RetryState(
                message:
                    'Your conversations will appear here after you connect with someone you crossed paths with.',
                actionLabel: 'View nearby connections',
                onRetry: () => context.go(AppRoutes.nearby),
              );
            }
            final profiles = ref.watch(
              publicPeerProfilesProvider(
                publicPeerIdsKey(
                  ordered.map(
                    (c) => c.userAId == currentUserId ? c.userBId : c.userAId,
                  ),
                ),
              ),
            );
            return ListView.builder(
              itemCount: ordered.length,
              itemBuilder: (context, index) {
                final connection = ordered[index];
                final conversation = _forConnection(items, connection.id);
                final otherId = connection.userAId == currentUserId
                    ? connection.userBId
                    : connection.userAId;
                return _ConversationTile(
                  conversation: conversation,
                  connectionId: connection.id,
                  currentUserId: currentUserId,
                  displayName: peerProfileLabel(profiles, otherId),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Conversation? _forConnection(List<Conversation> items, String connectionId) =>
      items.where((item) => item.connectionId == connectionId).firstOrNull;
}

class _ConversationTile extends ConsumerWidget {
  const _ConversationTile({
    required this.conversation,
    required this.connectionId,
    required this.currentUserId,
    required this.displayName,
  });

  final Conversation? conversation;
  final String connectionId;
  final String currentUserId;
  final String displayName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = conversation == null
        ? null
        : ref.watch(chatLatestMessageProvider(conversation!.id));
    final preview =
        messages?.when(
          data: (message) => message?.text ?? 'Start a conversation',
          loading: () => 'Loading messages…',
          error: (_, _) => 'Messages unavailable',
        ) ??
        'Start a conversation';
    return ListTile(
      leading: ProfileAvatar(displayName: displayName, radius: 24),
      title: Text(displayName),
      subtitle: Text(preview, maxLines: 2, overflow: TextOverflow.ellipsis),
      onTap: () => _open(context, ref),
    );
  }

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    try {
      final selected =
          conversation ??
          await ref
              .read(chatRepositoryProvider)
              .getOrCreateConversation(
                connectionId: connectionId,
                userId: currentUserId,
              );
      ref.invalidate(chatConversationsProvider);
      if (context.mounted) context.push('/app/chat/${selected.id}');
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This conversation is no longer available.'),
          ),
        );
      }
    }
  }
}

class _RetryState extends StatelessWidget {
  const _RetryState({
    required this.message,
    required this.onRetry,
    this.actionLabel = 'Try again',
  });
  final String message;
  final VoidCallback onRetry;
  final String actionLabel;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: Text(actionLabel)),
        ],
      ),
    ),
  );
}
