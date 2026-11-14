import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/identity/identity_providers.dart';
import '../../../core/auth/auth_providers.dart';
import '../../../core/identity/current_user_provider.dart';
import '../data/chat_providers.dart';
import '../../profile/data/public_peer_profiles.dart';
import '../../connections/data/connection_providers.dart';
import 'package:uuid/uuid.dart';
import '../../../core/observability/observability.dart';
import '../../../core/observability/observability_provider.dart';

class ConversationScreen extends ConsumerStatefulWidget {
  const ConversationScreen({required this.conversationId, super.key});
  final String conversationId;

  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen>
    with WidgetsBindingObserver {
  final input = TextEditingController();
  String? _clientMessageId;
  String? _clientMessageText;
  bool _sending = false;
  bool _refreshing = false;
  Timer? _refreshTimer;

  Future<void> _refresh() async {
    if (!mounted ||
        _refreshing ||
        !ref.read(productionModeProvider) ||
        !TickerMode.valuesOf(context).enabled ||
        WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
      return;
    }
    _refreshing = true;
    try {
      // Recheck the relationship as well as messages: a remote block/removal
      // must revoke access through the existing authorized repository paths.
      ref.invalidate(connectionsProvider);
      await ref.read(connectionsProvider.future);
      if (!mounted) return;
      ref.invalidate(chatMessagesProvider(widget.conversationId));
      await ref.read(chatMessagesProvider(widget.conversationId).future);
    } catch (_) {
      // Provider error UI keeps revoked/unavailable conversations closed.
    } finally {
      _refreshing = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_refresh());
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (ref.read(productionModeProvider)) {
        _refreshTimer = Timer.periodic(
          const Duration(seconds: 10),
          (_) => unawaited(_refresh()),
        );
      }
      ref.read(observabilityProvider).log(MitzoneEvents.conversationOpened);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final production = ref.watch(productionModeProvider);
    final identity = production
        ? null
        : ref.watch(mockIdentityRepositoryProvider);
    final currentUserId = production
        ? (ref.watch(currentUserIdProvider).value ?? '')
        : identity!.currentUser.id;
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
    final profiles = ref.watch(
      publicPeerProfilesProvider(publicPeerIdsKey([?otherId])),
    );
    final displayName = otherId == null
        ? 'Conversation'
        : peerProfileLabel(profiles, otherId);
    return Scaffold(
      appBar: AppBar(title: Text(displayName)),
      body: messages.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('This conversation is unavailable right now.'),
              TextButton(
                onPressed: () =>
                    ref.invalidate(chatMessagesProvider(widget.conversationId)),
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
        data: (items) => Column(
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
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final message = items[index];
                  final mine = message.senderUserId == currentUserId;
                  final author = mine ? 'You' : displayName;
                  final localTime = message.sentAt.toLocal();
                  final time = MaterialLocalizations.of(context)
                      .formatTimeOfDay(
                        TimeOfDay.fromDateTime(localTime),
                        alwaysUse24HourFormat:
                            MediaQuery.alwaysUse24HourFormatOf(context),
                      );
                  final date = MaterialLocalizations.of(
                    context,
                  ).formatMediumDate(localTime);
                  return Semantics(
                    label: '$author, $date, $time. ${message.text}',
                    child: ExcludeSemantics(
                      child: Align(
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                author,
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(message.text),
                              const SizedBox(height: 4),
                              Text(
                                '$date · $time',
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: input,
                      enabled: !_sending,
                      maxLength: 2000,
                      decoration: const InputDecoration(
                        labelText: 'Message',
                        counterText: '',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  IconButton(
                    tooltip: _sending ? 'Sending message' : 'Send message',
                    icon: _sending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                    onPressed:
                        _sending ||
                            input.text.trim().isEmpty ||
                            currentUserId.isEmpty
                        ? null
                        : () => _send(currentUserId),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _send(String currentUserId) async {
    if (_sending || input.text.trim().isEmpty || currentUserId.isEmpty) return;
    final text = input.text.trim();
    if (_clientMessageText != text) {
      _clientMessageText = text;
      _clientMessageId = const Uuid().v4();
    }
    setState(() => _sending = true);
    try {
      await ref
          .read(chatRepositoryProvider)
          .sendMessage(
            conversationId: widget.conversationId,
            senderUserId: currentUserId,
            text: text,
            clientMessageId: _clientMessageId ??= const Uuid().v4(),
          );
      if (!mounted) return;
      input.clear();
      _clientMessageId = null;
      _clientMessageText = null;
      ref.invalidate(chatMessagesProvider(widget.conversationId));
      ref.invalidate(chatConversationsProvider);
      ref.read(observabilityProvider).log(MitzoneEvents.messageSent);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Your message could not be sent. Your draft is kept.',
            ),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.fromLTRB(16, 0, 16, 80),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }
}
