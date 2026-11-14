import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/mitzone_card.dart';
import '../../../app/router/app_routes.dart';
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
        error: (_, _) => MitzoneEmptyState(
          title: 'Unable to load encounters',
          message: 'Your shared moments could not be loaded.',
          icon: Icons.people_outline,
          primaryAction: TextButton(
            onPressed: () => ref.invalidate(encountersForCurrentUserProvider),
            child: const Text('Try again'),
          ),
        ),
        data: (items) => Column(
          children: [
            if (incoming.isLoading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Loading connection requests…'),
              ),
            if (incoming.hasError)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text('Connection requests could not be loaded.'),
                    TextButton(
                      onPressed: () =>
                          ref.invalidate(incomingConnectionRequestsProvider),
                      child: const Text('Retry requests'),
                    ),
                  ],
                ),
              ),
            if ((incoming.value ?? const <ConnectionRequest>[]).isNotEmpty)
              _RequestsSection(
                requests: incoming.value ?? const <ConnectionRequest>[],
                encounters: items,
              ),
            if (items.isEmpty)
              MitzoneEmptyState(
                title: 'No shared moments yet',
                message:
                    'Choose voluntary presence from Home to discover shared experiences. Browsing or joining an event does not activate presence.',
                icon: Icons.people_outline,
                primaryAction: TextButton(
                  onPressed: () => context.go(AppRoutes.home),
                  child: const Text('Go to Home'),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.only(top: 24, bottom: 32),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _EncounterCard(encounter: items[i]),
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
    final userState = ref.watch(
      encounterProfileProvider(encounter.otherUserId),
    );
    final currentState = ref.watch(
      encounterProfileProvider(encounter.currentUserId),
    );
    if (!userState.hasValue || !currentState.hasValue) {
      return const SizedBox.shrink();
    }
    final user = userState.value;
    final current = currentState.value;
    if (user == null || current == null) return const SizedBox.shrink();
    final event = ref.watch(encounterEventProvider(encounter.eventId));
    final relationship = ref.watch(relationshipProvider(encounter));
    final interests = ProfileAffinity.sharedInterests(
      current.toUserProfile(),
      user.toUserProfile(),
    );
    return MitzoneCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                child: Text(
                  user.displayName.isEmpty
                      ? '?'
                      : user.displayName.substring(0, 1),
                ),
              ),
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
          if (event != null) ...[
            const Text('Shared event context'),
            Text(event.title, style: Theme.of(context).textTheme.titleMedium),
          ] else if (encounter.eventId.startsWith('cell:')) ...[
            Text(
              'A shared area',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Text(
              'Coarse presence overlap. Exact locations are not shown.',
            ),
          ] else ...[
            Text(
              'Shared experience',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Text('Details about this past context are unavailable.'),
          ],
          Text('Shared for ${encounter.overlapDuration.inMinutes}m'),
          if (interests.isNotEmpty) Text(interests.take(3).join(' · ')),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: () => context.push(
                  '/app/matches/profile/${user.id}/${encounter.id}',
                ),
                child: const Text('View profile'),
              ),
              relationship.when(
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const Text('Unavailable'),
                data: (state) => switch (state) {
                  RelationshipState.blocked => const Text('Unavailable'),
                  RelationshipState.outgoingPending => const Text(
                    'Request sent',
                  ),
                  RelationshipState.incomingPending => const Text(
                    'Incoming request',
                  ),
                  RelationshipState.declined => const Text('Not now'),
                  RelationshipState.none => _SayHiAction(encounter: encounter),
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
}

class _RequestsSection extends ConsumerWidget {
  const _RequestsSection({required this.requests, required this.encounters});
  final List<ConnectionRequest> requests;
  final List<Encounter> encounters;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Padding(
        padding: EdgeInsets.only(top: 16),
        child: Text(
          'Connection requests',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      for (final r in requests)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: MitzoneCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ref
                          .watch(encounterProfileProvider(r.senderUserId))
                          .value
                          ?.displayName ??
                      'Someone',
                ),
                const Text('They said hi.'),
                _RequestContext(request: r, encounters: encounters),
                const SizedBox(height: 8),
                _RequestDecisionActions(key: ValueKey(r.id), request: r),
              ],
            ),
          ),
        ),
    ],
  );
}

/// Only reuse context already authorized and returned with this user's
/// encounters. Do not infer a location from opaque context IDs or coordinates.
class _RequestContext extends ConsumerWidget {
  const _RequestContext({required this.request, required this.encounters});
  final ConnectionRequest request;
  final List<Encounter> encounters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final encounter = encounters
        .where(
          (item) =>
              item.id == request.encounterId &&
              item.otherUserId == request.senderUserId,
        )
        .firstOrNull;
    if (encounter == null) {
      return const Text('Shared experience details are unavailable.');
    }
    final event = ref.watch(encounterEventProvider(encounter.eventId));
    if (event != null) return Text('You crossed paths at ${event.title}.');
    if (encounter.eventId.startsWith('cell:')) {
      return const Text(
        'You crossed paths in a shared area. Exact locations are not shown.',
      );
    }
    return const Text('You crossed paths during a shared experience.');
  }
}

class _SayHiAction extends ConsumerStatefulWidget {
  const _SayHiAction({required this.encounter});
  final Encounter encounter;
  @override
  ConsumerState<_SayHiAction> createState() => _SayHiActionState();
}

class _SayHiActionState extends ConsumerState<_SayHiAction> {
  bool busy = false;
  Future<void> send() async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await ref
          .read(connectionControllerProvider)
          .send(widget.encounter.otherUserId, widget.encounter.id);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('We could not send your request. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: busy ? null : send,
    child: busy ? const Text('Sending…') : const Text('Say Hi'),
  );
}

class _RequestDecisionActions extends ConsumerStatefulWidget {
  const _RequestDecisionActions({required this.request, super.key});
  final ConnectionRequest request;
  @override
  ConsumerState<_RequestDecisionActions> createState() =>
      _RequestDecisionActionsState();
}

class _RequestDecisionActionsState
    extends ConsumerState<_RequestDecisionActions> {
  bool busy = false;
  bool accepting = false;
  Future<void> decide(bool accept) async {
    if (busy) return;
    setState(() {
      busy = true;
      accepting = accept;
    });
    try {
      final controller = ref.read(connectionControllerProvider);
      if (accept) {
        await controller.accept(widget.request.id);
      } else {
        await controller.decline(widget.request.id);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'We could not update this request. Please try again.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      TextButton(
        onPressed: busy ? null : () => decide(false),
        child: Text(busy && !accepting ? 'Updating…' : 'Not now'),
      ),
      FilledButton(
        onPressed: busy ? null : () => decide(true),
        child: Text(busy && accepting ? 'Accepting…' : 'Accept'),
      ),
    ],
  );
}
