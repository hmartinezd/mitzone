import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/mitzone_card.dart';
import '../../../shared/widgets/mitzone_empty_state.dart';
import '../../../shared/widgets/mitzone_page_body.dart';
import '../../connections/data/connection_providers.dart';
import '../../connections/domain/connection_repository.dart';
import '../../connections/domain/connection_request.dart';
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
    final requests = incoming.when(
      data: (value) => value,
      loading: () => const <ConnectionRequest>[],
      error: (_, _) => const <ConnectionRequest>[],
    );
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
            if (requests.isNotEmpty) _RequestsSection(requests: requests),
            if (items.isEmpty)
              const MitzoneEmptyState(
                title: 'No shared moments yet',
                message:
                    'Check in at events to discover people you actually crossed paths with.',
                icon: Icons.people_outline,
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: 24, bottom: 32),
                child: Column(
                  children: [
                    for (var index = 0; index < items.length; index++) ...[
                      if (index > 0) const SizedBox(height: 12),
                      _EncounterCard(encounter: items[index]),
                    ],
                  ],
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
    final relationship = ref.watch(relationshipProvider(encounter.otherUserId));
    if (event == null) return const SizedBox.shrink();
    final interests = ProfileAffinity.sharedInterests(current, user);
    final duration = encounter.overlapDuration;
    final durationLabel =
        '${duration.inHours > 0 ? '${duration.inHours}h ' : ''}${duration.inMinutes.remainder(60)}m';
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
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('You were both at'),
          Text(
            event.title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(
            '${_time(encounter.overlapStart)} – ${_time(encounter.overlapEnd)} · Shared for $durationLabel',
          ),
          if (interests.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(interests.take(3).join(' · ')),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton(
                onPressed: () => _showProfile(context, user, event.title),
                child: const Text('View profile'),
              ),
              relationship.when(
                data: (state) => switch (state) {
                  RelationshipState.outgoingPending => const Text(
                    'Request sent',
                  ),
                  RelationshipState.incomingPending => const Text(
                    'Incoming request',
                  ),
                  RelationshipState.connected => const Text('Connected'),
                  RelationshipState.declined => const Text('Not now'),
                  RelationshipState.none => TextButton(
                    onPressed: () => ref
                        .read(connectionControllerProvider)
                        .send(encounter.otherUserId, encounter.id),
                    child: const Text('Say Hi'),
                  ),
                },
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const Text('Unavailable'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _time(DateTime value) {
    final local = value.toLocal();
    return '${local.hour % 12 == 0 ? 12 : local.hour % 12}:${local.minute.toString().padLeft(2, '0')} ${local.hour >= 12 ? 'PM' : 'AM'}';
  }

  void _showProfile(BuildContext context, UserProfile user, String event) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(user.displayName),
        content: Text(
          '${user.bio ?? ''}\n${user.city ?? ''}\n\n$event\n\nInterests: ${user.interests.join(' · ')}\nLanguages: ${user.languages.join(' · ')}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
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
      for (final request in requests)
        ListTile(
          title: Text(
            ref
                .watch(encounterProfileProvider(request.senderUserId))
                .displayName,
          ),
          subtitle: const Text('You crossed paths. They said hi.'),
          trailing: Wrap(
            children: [
              TextButton(
                onPressed: () =>
                    ref.read(connectionControllerProvider).decline(request.id),
                child: const Text('Not now'),
              ),
              FilledButton(
                onPressed: () =>
                    ref.read(connectionControllerProvider).accept(request.id),
                child: const Text('Accept'),
              ),
            ],
          ),
        ),
    ],
  );
}
