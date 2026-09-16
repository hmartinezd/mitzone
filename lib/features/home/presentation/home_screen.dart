import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/mitzone_page_body.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/router/app_routes.dart';
import '../../../core/identity/identity_providers.dart';
import '../../../core/auth/auth_providers.dart';
import '../../../core/identity/current_user_provider.dart';
import '../../chat/data/chat_providers.dart';
import '../../connections/data/connection_providers.dart';
import '../../encounters/data/encounter_providers.dart';
import '../../profile/data/profile_providers.dart';
import '../../events/data/event_providers.dart';
import 'widgets/home_header.dart';
import 'widgets/discovery_section.dart';
import 'widgets/home_social_summary.dart';
import '../../encounters/presentation/foreground_presence_card.dart';
import 'home_activity_priority.dart';
import '../../discovery/data/discovery_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);
    final catalog = ref.watch(eventCatalogProvider);
    final interests = profileAsync.value?.interests.toSet() ?? const <String>{};
    final discovery = ref.watch(nearbyDiscoveryProvider(interests));
    final production = ref.watch(productionModeProvider);
    final identity = production ? null : ref.watch(mockIdentityRepositoryProvider);
    final encounters = ref.watch(encountersForCurrentUserProvider);
    final incomingRequests = ref.watch(incomingConnectionRequestsProvider);
    final connections = ref.watch(connectionsProvider);
    final conversations = ref.watch(chatConversationsProvider);
    final priority = homeActivityPriority(
      encounters: encounters.value?.length ?? 0,
      incomingRequests: incomingRequests.value?.length ?? 0,
      connections: connections.value?.length ?? 0,
      conversations: conversations.value?.length ?? 0,
    );
    return MitzonePageBody(
      title: null, // We use custom header instead of default title
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.lg),
          profileAsync.when(
            data: (profile) {
              if (profile == null) {
                return Column(
                  children: [
                    const HomeHeader(displayName: null),
                    const SizedBox(height: AppSpacing.md),
                    _HomeMissingProfile(
                      onFinish: () => ref.invalidate(currentProfileProvider),
                    ),
                  ],
                );
              }
              return HomeHeader(displayName: profile.displayName);
            },
            loading: () => const HomeHeader(displayName: null),
            error: (err, stack) => Column(
              children: [
                const HomeHeader(displayName: null),
                const SizedBox(height: AppSpacing.md),
                _HomeProfileError(
                  onRetry: () => ref.invalidate(currentProfileProvider),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          if (priority != HomeActivityPriority.lowActivity) ...[
            HomeSocialSummary(
              encounters: encounters,
              incomingRequests: incomingRequests,
              connections: connections,
              conversations: conversations,
              currentUserId: production
                  ? (ref.watch(currentUserIdProvider).value ?? '')
                  : identity!.currentUser.id,
              users: production ? const [] : identity!.users,
              eventCatalog: catalog,
              onExploreEvents: () => context.go(AppRoutes.events),
              onViewMatches: () => context.go(AppRoutes.matches),
              onOpenChat: () => context.go(AppRoutes.chat),
              onOpenConversation: (id) => context.go('${AppRoutes.chat}/$id'),
              onRetryEncounters: () =>
                  ref.invalidate(encountersForCurrentUserProvider),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
          if (priority == HomeActivityPriority.lowActivity) ...[
            Text(
              'Where will you be?',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Go somewhere. Be present. Mitzone does the rest.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
          const ForegroundPresenceCard(),
          const SizedBox(height: AppSpacing.xxl),
          discovery.when(
            data: (items) => items.isEmpty
                ? const _DiscoveryUnavailable(message: 'Nothing nearby was found yet.')
                : DiscoverySection(
              items: items,
              showDemoBadge: !production,
              onSeeAll: () => context.go(AppRoutes.events),
              onItemTap: (_) {},
            ),
            loading: () => const SizedBox(height: 220, child: Center(child: CircularProgressIndicator())),
            error: (_, _) => _DiscoveryUnavailable(
              message: 'We couldn’t load nearby discovery right now.',
              onRetry: () => ref.invalidate(nearbyDiscoveryProvider(interests)),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

class _DiscoveryUnavailable extends StatelessWidget {
  const _DiscoveryUnavailable({required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
    child: Row(children: [
      Expanded(child: Text(message)),
      if (onRetry != null) TextButton(onPressed: onRetry, child: const Text('Try again')),
    ]),
  );
}

class _HomeProfileError extends StatelessWidget {
  const _HomeProfileError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: theme.colorScheme.error),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              "We couldn't load your profile.",
              style: theme.textTheme.bodyMedium,
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}

class _HomeMissingProfile extends StatelessWidget {
  const _HomeMissingProfile({required this.onFinish});
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.info_outline, color: theme.colorScheme.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              "Complete your profile to get the most out of Mitzone.",
              style: theme.textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          TextButton(onPressed: onFinish, child: const Text('Finish now')),
        ],
      ),
    );
  }
}
