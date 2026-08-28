import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/identity/identity_providers.dart';
import '../data/chat_providers.dart';

class ConversationScreen extends ConsumerStatefulWidget {
  const ConversationScreen({required this.conversationId, super.key});
  final String conversationId;

  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  final input = TextEditingController();

  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = ref
        .watch(mockIdentityRepositoryProvider)
        .currentUser
        .id;
    final messages = ref.watch(chatMessagesProvider(widget.conversationId));
    final conversations = ref.watch(chatConversationsProvider);
    final contextState = ref.watch(
      conversationContextProvider(widget.conversationId),
    );
    final contextText = contextState.hasValue ? contextState.value : null;
    final conversation = conversations.hasValue
        ? (conversations.value ?? const [])
              .where((c) => c.id == widget.conversationId)
              .firstOrNull
        : null;
    final otherId = conversation == null
        ? null
        : conversation.userAId == currentUserId
        ? conversation.userBId
        : conversation.userAId;
    final other = otherId == null
        ? null
        : ref
              .watch(mockIdentityRepositoryProvider)
              .users
              .where((u) => u.id == otherId)
              .firstOrNull;
    return Scaffold(
      appBar: AppBar(title: Text(other?.displayName ?? 'Conversation')),
      body: Column(
        children: [
          if (contextText != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Text(
                contextText,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          Expanded(
            child: messages.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => const Center(
                child: Text('This conversation is unavailable right now.'),
              ),
              data: (items) => ListView(
                padding: const EdgeInsets.all(16),
                children: items.map((message) {
                  final mine = message.senderUserId == currentUserId;
                  return Align(
                    alignment: mine
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: mine
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(message.text),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          SafeArea(
            child: Row(
              children: [
                Expanded(child: TextField(controller: input)),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => _send(currentUserId),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _send(String currentUserId) async {
    try {
      await ref
          .read(chatRepositoryProvider)
          .sendMessage(
            conversationId: widget.conversationId,
            senderUserId: currentUserId,
            text: input.text,
          );
      input.clear();
      ref.invalidate(chatMessagesProvider(widget.conversationId));
      ref.invalidate(chatConversationsProvider);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your message could not be sent.')),
        );
      }
    }
  }
}
