import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/identity/current_user_provider.dart';
import '../../../shared/widgets/mitzone_card.dart';
import '../../chat/data/chat_providers.dart';
import '../../connections/data/connection_providers.dart';
import '../../connections/domain/connection.dart';
import '../../encounters/data/encounter_resolvers.dart';
import '../../matches/presentation/matches_screen.dart';
import '../../navigation/presentation/feature_destination_header.dart';
import '../../profile/presentation/widgets/profile_avatar.dart';

class NearbyScreen extends StatefulWidget {
  const NearbyScreen({this.showConnections = false, super.key});
  final bool showConnections;
  @override
  State<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends State<NearbyScreen> {
  late bool connections = widget.showConnections;
  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: Column(
      children: [
        const FeatureDestinationHeader(
          title: 'Nearby',
          subtitle:
              'Shared experiences, requests and people you chose to connect with.',
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Shared moments'),
                selected: !connections,
                onSelected: (_) => setState(() => connections = false),
              ),
              ChoiceChip(
                label: const Text('Connections'),
                selected: connections,
                onSelected: (_) => setState(() => connections = true),
              ),
            ],
          ),
        ),
        Expanded(
          child: connections
              ? const _ConnectionsPanel()
              : const MatchesScreen(),
        ),
      ],
    ),
  );
}

class _ConnectionsPanel extends ConsumerWidget {
  const _ConnectionsPanel();
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(connectionsProvider)
      .when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Your connections could not be loaded.'),
                TextButton(
                  onPressed: () => ref.invalidate(connectionsProvider),
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
        data: (items) => items.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Your mutual connections will appear here. Review shared moments to choose who to connect with.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (_, index) =>
                    _ConnectionCard(connection: items[index]),
              ),
      );
}

class _ConnectionCard extends ConsumerStatefulWidget {
  const _ConnectionCard({required this.connection});
  final Connection connection;
  @override
  ConsumerState<_ConnectionCard> createState() => _ConnectionCardState();
}

class _ConnectionCardState extends ConsumerState<_ConnectionCard> {
  bool opening = false;
  Future<void> message(String userId) async {
    if (opening) return;
    setState(() => opening = true);
    try {
      final conversation = await ref
          .read(chatRepositoryProvider)
          .getOrCreateConversation(
            connectionId: widget.connection.id,
            userId: userId,
          );
      ref.invalidate(chatConversationsProvider);
      if (mounted) {
        context.push('${AppRoutes.chat}/${conversation.id}');
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'This conversation is unavailable. Please try again.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => opening = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => ref
      .watch(currentUserIdProvider)
      .when(
        loading: () => const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text('Loading connection…'),
          ),
        ),
        error: (_, _) => const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text('Sign in to view this connection.'),
          ),
        ),
        data: (userId) {
          final otherId = widget.connection.userAId == userId
              ? widget.connection.userBId
              : widget.connection.userAId;
          final profile = ref.watch(encounterProfileProvider(otherId));
          final name = profile.value?.displayName ?? 'Connection';
          return MitzoneCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ProfileAvatar(
                      displayName: name,
                      avatarUri: profile.value?.avatarUri,
                      radius: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  profile.hasError
                      ? 'Profile details are unavailable.'
                      : 'You both chose to connect.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: opening ? null : () => message(userId),
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: Text(opening ? 'Opening…' : 'Message'),
                ),
              ],
            ),
          );
        },
      );
}
