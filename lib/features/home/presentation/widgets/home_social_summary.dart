import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../shared/widgets/mitzone_card.dart';
import '../../../chat/domain/chat_models.dart';
import '../../../connections/domain/connection.dart';
import '../../../connections/domain/connection_request.dart';
import '../../../encounters/domain/encounter.dart';
import '../../../events/domain/event_catalog.dart';
import '../../../profile/domain/user_profile.dart';

class HomeSocialSummary extends StatelessWidget {
  const HomeSocialSummary({
    required this.encounters,
    required this.incomingRequests,
    required this.connections,
    required this.conversations,
    required this.currentUserId,
    required this.users,
    required this.eventCatalog,
    required this.onExploreEvents,
    required this.onViewMatches,
    required this.onOpenChat,
    required this.onOpenConversation,
    required this.onRetryEncounters,
    super.key,
  });

  final AsyncValue<List<Encounter>> encounters;
  final AsyncValue<List<ConnectionRequest>> incomingRequests;
  final AsyncValue<List<Connection>> connections;
  final AsyncValue<List<Conversation>> conversations;
  final String currentUserId;
  final List<UserProfile> users;
  final EventCatalog eventCatalog;
  final VoidCallback onExploreEvents;
  final VoidCallback onViewMatches;
  final VoidCallback onOpenChat;
  final ValueChanged<String> onOpenConversation;
  final VoidCallback onRetryEncounters;

  @override
  Widget build(BuildContext context) {
    final requestItems = incomingRequests.value ?? const <ConnectionRequest>[];
    final connectionItems = connections.value ?? const <Connection>[];
    final conversationItems = conversations.value ?? const <Conversation>[];
    final hasAdvancedState =
        requestItems.isNotEmpty ||
        connectionItems.isNotEmpty ||
        conversationItems.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your connections',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.md),
        _RequestState(state: incomingRequests, onReview: onViewMatches),
        if (requestItems.isNotEmpty) const SizedBox(height: AppSpacing.md),
        _ConversationState(
          state: conversations,
          connections: connectionItems,
          currentUserId: currentUserId,
          displayNameFor: _displayName,
          eventCatalog: eventCatalog,
          onOpenChat: onOpenChat,
          onOpenConversation: onOpenConversation,
        ),
        if (conversationItems.isNotEmpty) const SizedBox(height: AppSpacing.md),
        _ConnectionState(state: connections, onViewMatches: onViewMatches),
        if (connectionItems.isNotEmpty) const SizedBox(height: AppSpacing.md),
        _EncounterState(
          state: encounters,
          suppressEmpty: hasAdvancedState,
          displayNameFor: _displayName,
          eventCatalog: eventCatalog,
          onExploreEvents: onExploreEvents,
          onViewMatches: onViewMatches,
          onRetry: onRetryEncounters,
        ),
      ],
    );
  }

  String _displayName(String userId) =>
      users
          .where((user) => user.id == userId)
          .map((user) => user.displayName)
          .firstOrNull ??
      'Someone';
}

class _RequestState extends StatelessWidget {
  const _RequestState({required this.state, required this.onReview});

  final AsyncValue<List<ConnectionRequest>> state;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) => state.when(
    loading: () => const _SectionLoading(label: 'Checking requests…'),
    error: (_, _) => const _SectionError(
      message: 'Connection requests are unavailable right now.',
    ),
    data: (items) {
      if (items.isEmpty) return const SizedBox.shrink();
      final count = items.length;
      return MitzoneCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person_add_alt_1),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    count == 1
                        ? '1 person wants to connect'
                        : '$count people want to connect',
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onReview,
                child: const Text('Review request'),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _ConnectionState extends StatelessWidget {
  const _ConnectionState({required this.state, required this.onViewMatches});

  final AsyncValue<List<Connection>> state;
  final VoidCallback onViewMatches;

  @override
  Widget build(BuildContext context) => state.when(
    loading: () => const _SectionLoading(label: 'Loading connections…'),
    error: (_, _) => const _SectionError(
      message: 'Your connections are unavailable right now.',
    ),
    data: (items) {
      if (items.isEmpty) return const SizedBox.shrink();
      return MitzoneCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.people_alt_outlined),
                SizedBox(width: AppSpacing.sm),
                Expanded(child: Text('Your connections')),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              items.length == 1
                  ? "1 person you've connected with"
                  : "${items.length} people you've connected with",
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onViewMatches,
                child: const Text('View matches'),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _ConversationState extends StatelessWidget {
  const _ConversationState({
    required this.state,
    required this.connections,
    required this.currentUserId,
    required this.displayNameFor,
    required this.eventCatalog,
    required this.onOpenChat,
    required this.onOpenConversation,
  });

  final AsyncValue<List<Conversation>> state;
  final List<Connection> connections;
  final String currentUserId;
  final String Function(String) displayNameFor;
  final EventCatalog eventCatalog;
  final VoidCallback onOpenChat;
  final ValueChanged<String> onOpenConversation;

  @override
  Widget build(BuildContext context) => state.when(
    loading: () => const _SectionLoading(label: 'Loading conversations…'),
    error: (_, _) => const _SectionError(
      message: 'Recent conversations are unavailable right now.',
    ),
    data: (items) {
      if (items.isEmpty) return const SizedBox.shrink();
      return MitzoneCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent conversations',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final conversation in items.take(2))
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  displayNameFor(
                    conversation.userAId == currentUserId
                        ? conversation.userBId
                        : conversation.userAId,
                  ),
                ),
                subtitle: Text(_contextFor(conversation) ?? 'Conversation'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => onOpenConversation(conversation.id),
              ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onOpenChat,
                child: const Text('Open chat'),
              ),
            ),
          ],
        ),
      );
    },
  );

  String? _contextFor(Conversation conversation) {
    final connection = connections
        .where((item) => item.id == conversation.connectionId)
        .firstOrNull;
    final eventId = connection?.contextId?.split(':').first;
    if (eventId == null) return null;
    return eventCatalog.getById(eventId)?.title;
  }
}

class _EncounterState extends StatelessWidget {
  const _EncounterState({
    required this.state,
    required this.suppressEmpty,
    required this.displayNameFor,
    required this.eventCatalog,
    required this.onExploreEvents,
    required this.onViewMatches,
    required this.onRetry,
  });

  final AsyncValue<List<Encounter>> state;
  final bool suppressEmpty;
  final String Function(String) displayNameFor;
  final EventCatalog eventCatalog;
  final VoidCallback onExploreEvents;
  final VoidCallback onViewMatches;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => state.when(
    loading: () => const _SectionLoading(label: 'Loading shared moments…'),
    error: (_, _) => _SectionError(
      message: 'Shared moments are unavailable right now.',
      actionLabel: 'Try again',
      onAction: onRetry,
    ),
    data: (items) {
      if (items.isEmpty) {
        if (suppressEmpty) return const SizedBox.shrink();
        return MitzoneCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.people_outline),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'No shared moments yet',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                'Check in at an event to discover people you crossed paths with.',
              ),
              const SizedBox(height: AppSpacing.sm),
              FilledButton(
                onPressed: onExploreEvents,
                child: const Text('Explore events'),
              ),
            ],
          ),
        );
      }
      return MitzoneCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'People you crossed paths with',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final encounter in items.take(3))
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(displayNameFor(encounter.otherUserId)),
                subtitle: Text(
                  eventCatalog.getById(encounter.eventId)?.title ??
                      'Shared event',
                ),
              ),
            Text(
              items.length == 1
                  ? '1 person from your recent moments'
                  : '${items.length} people from your recent moments',
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onViewMatches,
                child: const Text('View matches'),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _SectionLoading extends StatelessWidget {
  const _SectionLoading({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
    child: Row(
      children: [
        const SizedBox.square(
          dimension: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(label)),
      ],
    ),
  );
}

class _SectionError extends StatelessWidget {
  const _SectionError({required this.message, this.actionLabel, this.onAction});

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
    child: Row(
      children: [
        const Icon(Icons.info_outline, size: 18),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(message)),
        if (actionLabel != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    ),
  );
}
