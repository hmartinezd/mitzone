import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/mitzone_card.dart';
import '../../../shared/widgets/mitzone_empty_state.dart';
import '../../../shared/widgets/mitzone_page_body.dart';
import '../data/encounter_providers.dart';
import '../domain/encounter.dart';
import '../domain/profile_affinity.dart';
import '../../profile/domain/user_profile.dart';
import '../../connections/data/connection_providers.dart';
import '../../connections/domain/connection_request.dart';

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
        error: (error, stack) => const MitzoneEmptyState(title: 'Unable to load encounters', message: 'Please try again later.', icon: Icons.people_outline),
        data: (items) => Column(children: [
          if (incoming.valueOrNull?.isNotEmpty ?? false) _RequestsSection(requests: incoming.valueOrNull!),
          Expanded(child: items.isEmpty
            ? const MitzoneEmptyState(title: 'No shared moments yet', message: 'Check in at events to discover people you actually crossed paths with.', icon: Icons.people_outline)
            : ListView.separated(padding: const EdgeInsets.only(top: 24, bottom: 32), itemCount: items.length, separatorBuilder: (_, __) => const SizedBox(height: 12), itemBuilder: (context, index) => _EncounterCard(encounter: items[index])),
          ),
        ]),
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
    final current = ref.watch(encounterProfileProvider(encounter.currentUserId));
    final event = ref.watch(encounterEventProvider(encounter.eventId));
    final requests = ref.watch(outgoingConnectionRequestsProvider).valueOrNull ?? const [];
    final relationship = requests.where((r) => r.encounterId == encounter.id && r.recipientUserId == encounter.otherUserId).firstOrNull;
    if (event == null) return const SizedBox.shrink();
    final sharedInterests = ProfileAffinity.sharedInterests(current, user);
    final d = encounter.overlapDuration;
    final duration = '${d.inHours > 0 ? '${d.inHours}h ' : ''}${d.inMinutes.remainder(60)}m';
    return MitzoneCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [CircleAvatar(child: Text(user.displayName.substring(0, 1))), const SizedBox(width: 12), Expanded(child: Text(user.displayName, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)))]),
      const SizedBox(height: 16),
      const Text('You were both at'),
      Text(event.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
      Text('${_time(encounter.overlapStart)} – ${_time(encounter.overlapEnd)} · Shared for $duration'),
      if (sharedInterests.isNotEmpty) ...[const SizedBox(height: 8), Text(sharedInterests.take(3).join(' · '))],
      const SizedBox(height: 12),
      Row(children: [
        OutlinedButton(onPressed: () => _showProfile(context, user, event.title), child: const Text('View profile')),
        const SizedBox(width: 8),
        if (relationship?.status == ConnectionRequestStatus.pending) const Text('Request sent')
        else if (relationship?.status == ConnectionRequestStatus.accepted) const Text('Connected')
        else if (relationship?.status == ConnectionRequestStatus.declined) const Text('Not now')
        else TextButton(onPressed: () async { await ref.read(connectionControllerProvider).send(encounter.otherUserId, encounter.id); }, child: const Text('Say Hi')),
    ]));
  }

  String _time(DateTime value) { final v = value.toLocal(); final h = v.hour; return '${h % 12 == 0 ? 12 : h % 12}:${v.minute.toString().padLeft(2, '0')} ${h >= 12 ? 'PM' : 'AM'}'; }
  void _showProfile(BuildContext context, UserProfile user, String event) => showDialog<void>(context: context, builder: (_) => AlertDialog(title: Text(user.displayName), content: Text('${user.bio ?? ''}\n${user.city ?? ''}\n\n$event\n\nInterests: ${user.interests.join(' · ')}\nLanguages: ${user.languages.join(' · ')}'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))]));
}

class _RequestsSection extends ConsumerWidget {
  const _RequestsSection({required this.requests});
  final List<ConnectionRequest> requests;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Padding(padding: EdgeInsets.only(top: 16), child: Text('REQUESTS', style: TextStyle(fontWeight: FontWeight.bold))),
    for (final request in requests) ListTile(title: Text(ref.watch(encounterProfileProvider(request.senderUserId)).displayName), subtitle: const Text('You crossed paths. They said hi.'), trailing: Wrap(children: [TextButton(onPressed: () => ref.read(connectionControllerProvider).decline(request.id), child: const Text('Not now')), FilledButton(onPressed: () => ref.read(connectionControllerProvider).accept(request.id), child: const Text('Accept'))])),
  ]);
