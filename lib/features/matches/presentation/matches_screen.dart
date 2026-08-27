import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/mitzone_card.dart';
import '../../../shared/widgets/mitzone_empty_state.dart';
import '../../../shared/widgets/mitzone_page_body.dart';
import '../data/encounter_providers.dart';
import '../domain/encounter.dart';
import '../domain/profile_affinity.dart';
import '../../profile/domain/user_profile.dart';

class MatchesScreen extends ConsumerWidget {
  const MatchesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final encounters = ref.watch(encountersForCurrentUserProvider);
    return MitzonePageBody(
      title: 'People you crossed paths with',
      child: encounters.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => const MitzoneEmptyState(title: 'Unable to load encounters', message: 'Please try again later.', icon: Icons.people_outline),
        data: (items) => items.isEmpty
            ? const MitzoneEmptyState(title: 'No shared moments yet', message: 'Check in at events to discover people you actually crossed paths with.', icon: Icons.people_outline)
            : ListView.separated(padding: const EdgeInsets.only(top: 24, bottom: 32), itemCount: items.length, separatorBuilder: (_, __) => const SizedBox(height: 12), itemBuilder: (context, index) => _EncounterCard(encounter: items[index])),
      ),
    );
  }
}

class _EncounterCard extends StatelessWidget {
  const _EncounterCard({required this.encounter});
  final Encounter encounter;
  @override
  Widget build(BuildContext context) {
    final user = ProviderScope.containerOf(context).read(encounterProfileProvider(encounter.otherUserId));
    final current = ProviderScope.containerOf(context).read(encounterProfileProvider(encounter.currentUserId));
    final event = ProviderScope.containerOf(context).read(encounterEventProvider(encounter.eventId));
    if (event == null) return const SizedBox.shrink();
    final d = encounter.overlapDuration;
    final duration = '${d.inHours > 0 ? '${d.inHours}h ' : ''}${d.inMinutes.remainder(60)}m';
    return MitzoneCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [CircleAvatar(child: Text(user.displayName.substring(0, 1))), const SizedBox(width: 12), Expanded(child: Text(user.displayName, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)))]),
      const SizedBox(height: 16),
      const Text('You were both at'),
      Text(event.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
      Text('${_time(encounter.overlapStart)} – ${_time(encounter.overlapEnd)} · Shared for $duration'),
      if (ProfileAffinity.sharedInterests(current, user).isNotEmpty) ...[const SizedBox(height: 8), Text(ProfileAffinity.sharedInterests(current, user).take(3).join(' · '))],
      const SizedBox(height: 12),
      Row(children: [
        OutlinedButton(onPressed: () => _showProfile(context, user, event.title), child: const Text('View profile')),
        const SizedBox(width: 8),
        TextButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Connections are coming next.'))), child: const Text('Say Hi')),
    ]));
  }

  String _time(DateTime value) { final v = value.toLocal(); final h = v.hour; return '${h % 12 == 0 ? 12 : h % 12}:${v.minute.toString().padLeft(2, '0')} ${h >= 12 ? 'PM' : 'AM'}'; }
  void _showProfile(BuildContext context, UserProfile user, String event) => showDialog<void>(context: context, builder: (_) => AlertDialog(title: Text(user.displayName), content: Text('${user.bio ?? ''}\n${user.city ?? ''}\n\n$event\n\nInterests: ${user.interests.join(' · ')}\nLanguages: ${user.languages.join(' · ')}'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))]));
}
