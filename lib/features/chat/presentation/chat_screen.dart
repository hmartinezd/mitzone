import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/identity/identity_providers.dart';
import '../../connections/data/connection_providers.dart';
import '../../profile/presentation/widgets/profile_avatar.dart';
import '../data/chat_providers.dart';
import '../domain/chat_models.dart';
import '../../notifications/data/notification_providers.dart';

class ChatScreen extends ConsumerWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversations = ref.watch(chatConversationsProvider);
    final connections = ref.watch(connectionsProvider);
    final identity = ref.watch(mockIdentityRepositoryProvider);
    final currentUserId = identity.currentUser.id;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        actions: [
          IconButton(
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
        error: (_, _) => const Center(
          child: Text('Your conversations are unavailable right now.'),
        ),
        data: (items) => connections.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const Center(
            child: Text('Your connections are unavailable right now.'),
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
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'Your conversations will appear here after you connect with someone you crossed paths with.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            return ListView(
              children: ordered.map((connection) {
                final conversation = _forConnection(items, connection.id);
                final otherId = connection.userAId == currentUserId
                    ? connection.userBId
                    : connection.userAId;
                final other = identity.users.firstWhere(
                  (user) => user.id == otherId,
                );
                return _ConversationTile(
                  conversation: conversation,
                  connectionId: connection.id,
                  currentUserId: currentUserId,
                  displayName: other.displayName,
                );
              }).toList(),
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
        : ref.watch(chatMessagesProvider(conversation!.id));
    final preview =
        messages?.when(
          data: (items) =>
              items.isEmpty ? 'Start a conversation' : items.last.text,
          loading: () => 'Loading messages…',
          error: (_, _) => 'Messages unavailable',
        ) ??
        'Start a conversation';
    return ListTile(
      leading: ProfileAvatar(displayName: displayName, radius: 24),
      title: Text(displayName),
      subtitle: Text(preview),
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
