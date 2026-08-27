import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitzone/features/connections/data/connection_providers.dart';
import 'package:mitzone/features/connections/domain/connection_request.dart';
import 'package:mitzone/features/encounters/data/encounter_providers.dart';
import 'package:mitzone/features/encounters/data/encounter_resolvers.dart';
import 'package:mitzone/features/encounters/domain/encounter.dart';
import 'package:mitzone/features/encounters/domain/profile_affinity.dart';
import 'package:mitzone/features/profile/domain/user_profile.dart';
import '../../../shared/widgets/mitzone_card.dart';
import '../../../shared/widgets/mitzone_empty_state.dart';
import '../../../shared/widgets/mitzone_page_body.dart';

class MatchesScreen extends ConsumerWidget {
  const MatchesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(encountersForCurrentUserProvider);
    final incoming = ref.watch(incomingConnectionRequestsProvider);
    return MitzonePageBody(title: 'People you crossed paths with', child: async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const MitzoneEmptyState(title: 'Unable to load encounters', message: 'Please try again later.', icon: Icons.people_outline),
      data: (items) => Column(children: [
        if (incoming.hasValue && incoming.value.isNotEmpty) _RequestsSection(requests: incoming.value),
        if (items.isEmpty) const MitzoneEmptyState(title: 'No shared moments yet', message: 'Check in at events to discover people you actually crossed paths with.', icon: Icons.people_outline)
        else ListView.separated(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: items.length, separatorBuilder: (_, __) => const SizedBox(height: 12), itemBuilder: (_, i) => _EncounterCard(encounter: items[i])),
      ]),
    ));
  }
}

class _EncounterCard extends ConsumerWidget {
  const _EncounterCard({required this.encounter});
  final Encounter encounter;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(encounterProfileProvider(encounter.otherUserId));
    final current = ref.watch(encounterProfileProvider(encounter.currentUserId));
    final event = ref.watch(encounterEventProvider(encounter.eventId));
    if (event == null) return const SizedBox.shrink();
    final shared = ProfileAffinity.sharedInterests(current, user);
    final outgoing = ref.watch(outgoingConnectionRequestsProvider);
    final request = outgoing.hasValue ? outgoing.value.where((r) => r.encounterId == encounter.id).firstOrNull : null;
    return MitzoneCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(user.displayName, style: Theme.of(context).textTheme.titleLarge),
      Text('You were both at ${event.title}'),
      Text('Shared for ${encounter.overlapDuration.inMinutes}m'),
      if (shared.isNotEmpty) Text('In common: ${shared.join(' · ')}'),
      Row(children: [
        OutlinedButton(onPressed: () => _showProfile(context, user, event.title), child: const Text('View profile')),
        if (request?.status == ConnectionRequestStatus.pending) const Text('Request sent')
        else if (request?.status == ConnectionRequestStatus.accepted) const Text('Connected')
        else if (request?.status == ConnectionRequestStatus.declined) const Text('Not now')
        else TextButton(onPressed: () => ref.read(connectionControllerProvider).send(user.id, encounter.id), child: const Text('Say Hi')),
      ]),
    ]));
  }
  void _showProfile(BuildContext context, UserProfile user, String event) {
    showDialog<void>(context: context, builder: (_) => AlertDialog(title: Text(user.displayName), content: Text('${user.bio ?? ''}\n${user.city ?? ''}\n$event\n${user.interests.join(', ')}'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))]));
  }
}

class _RequestsSection extends ConsumerWidget {
  const _RequestsSection({required this.requests});
  final List<ConnectionRequest> requests;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(children: [
    const Align(alignment: Alignment.centerLeft, child: Text('REQUESTS', style: TextStyle(fontWeight: FontWeight.bold))),
    for (final request in requests) ListTile(title: Text(ref.watch(encounterProfileProvider(request.senderUserId)).displayName), subtitle: const Text('You crossed paths. They said hi.'), trailing: Wrap(children: [TextButton(onPressed: () => ref.read(connectionControllerProvider).decline(request.id), child: const Text('Not now')), FilledButton(onPressed: () => ref.read(connectionControllerProvider).accept(request.id), child: const Text('Accept'))])),
  ]);
}
