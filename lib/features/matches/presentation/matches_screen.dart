import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/mitzone_card.dart';
import '../../../shared/widgets/mitzone_empty_state.dart';
import '../../../shared/widgets/mitzone_page_body.dart';
import '../../chat/data/chat_providers.dart';
import '../../connections/data/connection_providers.dart';
import '../../connections/domain/connection_request.dart';
import '../../connections/domain/connection_repository.dart';
import '../../encounters/data/encounter_providers.dart';
import '../../encounters/data/encounter_resolvers.dart';
import '../../encounters/domain/encounter.dart';
import '../../encounters/domain/profile_affinity.dart';
import '../../profile/domain/user_profile.dart';

class MatchesScreen extends ConsumerWidget {
  const MatchesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final encounters = ref.watch(encountersForCurrentUserProvider);
    final incoming = ref.watch(incomingConnectionRequestsProvider);
    return MitzonePageBody(
      title: 'People you crossed paths with',
      child: encounters.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const MitzoneEmptyState(
          title: 'Unable to load encounters',
          message: 'Please try again later.',
          icon: Icons.people_outline,
        ),
        data: (items) => Column(
          children: [
            if ((incoming.value ?? const <ConnectionRequest>[]).isNotEmpty)
              _RequestsSection(
                requests: incoming.value ?? const <ConnectionRequest>[],
              ),
            Expanded(
              child: items.isEmpty
                  ? const MitzoneEmptyState(
                      title: 'No shared moments yet',
                      message:
                          'Check in at events to discover people you actually crossed paths with.',
                      icon: Icons.people_outline,
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.only(top: 24, bottom: 32),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (_, i) =>
                          _EncounterCard(encounter: items[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EncounterCard extends ConsumerWidget {
  const _EncounterCard({required this.encounter});
  final Encounter encounter;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(encounterProfileProvider(encounter.otherUserId));
    final current = ref.watch(
      encounterProfileProvider(encounter.currentUserId),
    );
    final event = ref.watch(encounterEventProvider(encounter.eventId));
    final relationship = ref.watch(relationshipProvider(encounter));
    if (event == null) return const SizedBox.shrink();
    final interests = ProfileAffinity.sharedInterests(current, user);
    return MitzoneCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(child: Text(user.displayName.substring(0, 1))),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  user.displayName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('You were both at'),
          Text(event.title, style: Theme.of(context).textTheme.titleMedium),
          Text('Shared for ${encounter.overlapDuration.inMinutes}m'),
          if (interests.isNotEmpty) Text(interests.take(3).join(' · ')),
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton(
                onPressed: () => _showProfile(context, user, event.title),
                child: const Text('View profile'),
              ),
              const SizedBox(width: 8),
              relationship.when(
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const Text('Unavailable'),
                data: (state) => switch (state) {
                  RelationshipState.outgoingPending => const Text(
                    'Request sent',
                  ),
                  RelationshipState.incomingPending => const Text(
                    'Incoming request',
                  ),
                  RelationshipState.declined => const Text('Not now'),
                  RelationshipState.none => TextButton(
                    onPressed: () => ref
                        .read(connectionControllerProvider)
                        .send(encounter.otherUserId, encounter.id),
                    child: const Text('Say Hi'),
                  ),
                  RelationshipState.connected => Wrap(
                    spacing: 8,
                    children: [
                      const Text('Connected'),
                      TextButton(
                        onPressed: () => _message(context, ref),
                        child: const Text('Message'),
                      ),
                    ],
                  ),
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _message(BuildContext context, WidgetRef ref) async {
    try {
      final cs = await ref.read(connectionsProvider.future);
      final c = cs.firstWhere(
        (c) =>
            (c.userAId == encounter.currentUserId &&
                c.userBId == encounter.otherUserId) ||
            (c.userAId == encounter.otherUserId &&
                c.userBId == encounter.currentUserId),
      );
      final chat = await ref
          .read(chatRepositoryProvider)
          .getOrCreateConversation(
            connectionId: c.id,
            userId: encounter.currentUserId,
          );
      if (context.mounted) context.push('/app/chat/${chat.id}');
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This conversation is unavailable right now.'),
          ),
        );
      }
    }
  }

  void _showProfile(BuildContext context, UserProfile user, String event) =>
      showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(user.displayName),
          content: Text('${user.bio ?? ''}\n${user.city ?? ''}\n\n$event'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
}

class _RequestsSection extends ConsumerWidget {
  const _RequestsSection({required this.requests});
  final List<ConnectionRequest> requests;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Padding(
        padding: EdgeInsets.only(top: 16),
        child: Text('REQUESTS', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      for (final r in requests)
        ListTile(
          title: Text(
            ref.watch(encounterProfileProvider(r.senderUserId)).displayName,
          ),
          subtitle: const Text('You crossed paths. They said hi.'),
          trailing: Wrap(
            children: [
              TextButton(
                onPressed: () =>
                    ref.read(connectionControllerProvider).decline(r.id),
                child: const Text('Not now'),
              ),
              FilledButton(
                onPressed: () =>
                    ref.read(connectionControllerProvider).accept(r.id),
                child: const Text('Accept'),
              ),
            ],
          ),
        ),
    ],
  );
}
