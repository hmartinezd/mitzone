import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_spacing.dart';
import '../../connections/data/connection_providers.dart';
import '../../connections/domain/connection_repository.dart';
import '../../chat/data/chat_providers.dart';
import '../../encounters/data/encounter_resolvers.dart';
import '../../encounters/data/encounter_providers.dart';
import '../../encounters/domain/encounter.dart';
import '../../encounters/domain/profile_affinity.dart';
import '../../profile/domain/user_profile.dart';
import 'widgets/profile_avatar.dart';

class OtherUserProfileScreen extends ConsumerWidget {
  const OtherUserProfileScreen({required this.userId, required this.encounterId, super.key});
  final String userId;
  final String encounterId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final encounterState = ref.watch(encountersForCurrentUserProvider);
    return encounterState.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) => const Scaffold(body: Center(child: Text('This encounter is no longer available.'))),
      data: (encounters) {
        final encounter = encounters.where((e) => e.id == encounterId && e.otherUserId == userId).firstOrNull;
        if (encounter == null) return const Scaffold(body: Center(child: Text('This encounter is no longer available.')));
        final profile = ref.watch(encounterProfileProvider(userId));
        return _content(context, ref, profile, encounter);
      },
    );
  }

  Widget _content(BuildContext context, WidgetRef ref, UserProfile profile, Encounter encounter) {
    final current = ref.watch(
      encounterProfileProvider(encounter.currentUserId),
    );
    final event = ref.watch(encounterEventProvider(encounter.eventId));
    final relationship = ref.watch(relationshipProvider(encounter));
    final sharedInterests = ProfileAffinity.sharedInterests(current, profile);
    final sharedLanguages = ProfileAffinity.sharedLanguages(current, profile);
    return Scaffold(
      appBar: AppBar(title: Text(profile.displayName)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Center(
            child: ProfileAvatar(
              displayName: profile.displayName,
              avatarUri: profile.avatarUri,
              radius: 50,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: Text(
              profile.displayName,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          if (_value(profile.city) != null)
            Center(child: Text(profile.city!.trim())),
          if (profile.connectionGoal != null)
            _InfoSection(
              title: 'Connection goal',
              child: Text(_goal(profile.connectionGoal!)),
            ),
          if (_value(profile.bio) != null)
            _InfoSection(title: 'About', child: Text(profile.bio!.trim())),
          if (profile.interests.isNotEmpty)
            _Chips(title: 'Interests', values: profile.interests),
          if (profile.languages.isNotEmpty)
            _Chips(title: 'Languages', values: profile.languages),
          _InfoSection(
            title: 'Why you crossed paths',
            child: Text(
              event == null
                  ? 'You shared a local Mitzone moment.'
                  : 'You were both at ${event.title}.',
            ),
          ),
          if (sharedInterests.isNotEmpty)
            _Chips(title: 'Shared interests', values: sharedInterests),
          if (sharedLanguages.isNotEmpty)
            _Chips(title: 'Shared languages', values: sharedLanguages),
          if (ProfileAffinity.sharedGoal(current, profile))
            _InfoSection(
              title: 'Shared connection goal',
              child: Text(_goal(profile.connectionGoal!)),
            ),
          const SizedBox(height: AppSpacing.lg),
          relationship.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => const Text('Relationship unavailable'),
            data: (state) =>
                _Action(state: state, encounter: encounter, profile: profile),
          ),
        ],
      ),
    );
  }

  static String? _value(String? value) =>
      value?.trim().isEmpty ?? true ? null : value;
  static String _goal(ConnectionGoal goal) => switch (goal) {
    ConnectionGoal.social => 'Social',
    ConnectionGoal.professional => 'Professional',
    ConnectionGoal.both => 'Social + Professional',
  };
}

class _Action extends ConsumerStatefulWidget {
  const _Action({
    required this.state,
    required this.encounter,
    required this.profile,
  });
  final RelationshipState state;
  final Encounter encounter;
  final UserProfile profile;
  @override ConsumerState<_Action> createState() => _ActionState();
}

class _ActionState extends ConsumerState<_Action> {
  bool busy = false;
  @override Widget build(BuildContext context) => switch (widget.state) {
    RelationshipState.none => FilledButton(
      onPressed: busy ? null : _sayHi,
      child: busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator()) : const Text('Say Hi'),
    ),
    RelationshipState.outgoingPending => const Center(
      child: Text('Request sent'),
    ),
    RelationshipState.incomingPending => const Center(
      child: Text('Review this request in Matches'),
    ),
    RelationshipState.declined => const Center(child: Text('Not now')),
    RelationshipState.connected => FilledButton(
      onPressed: () async {
        final cs = await ref.read(connectionsProvider.future);
        final c = cs.firstWhere(
          (c) => c.userAId == widget.profile.id || c.userBId == widget.profile.id,
        );
        final chat = await ref
            .read(chatRepositoryProvider)
            .getOrCreateConversation(
              connectionId: c.id,
            userId: widget.encounter.currentUserId,
            );
        if (context.mounted) context.push('/app/chat/${chat.id}');
      },
      child: const Text('Message'),
    ),
  };

  Future<void> _sayHi() async {
    setState(() => busy = true);
    try {
      await ref.read(connectionControllerProvider).send(widget.profile.id, widget.encounter.id);
      ref.invalidate(relationshipProvider(widget.encounter));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('We could not send your request.')));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext c) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.xl),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(c).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        child,
      ],
    ),
  );
}

class _Chips extends StatelessWidget {
  const _Chips({required this.title, required this.values});
  final String title;
  final List<String> values;
  @override
  Widget build(BuildContext c) => _InfoSection(
    title: title,
    child: Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: values.map((v) => Chip(label: Text(v))).toList(),
    ),
  );
}
