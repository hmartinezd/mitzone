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
import '../../events/data/demo_events.dart';
import '../../events/data/event_providers.dart';
import '../../events/domain/event.dart';
import 'widgets/home_header.dart';
import 'widgets/home_welcome_card.dart';
import 'widgets/home_event_section.dart';
import 'widgets/home_profile_card.dart';
import 'widgets/home_social_summary.dart';
import 'widgets/how_mitzone_works.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);
    final joinedIdsAsync = ref.watch(joinedEventIdsProvider);
    final catalog = ref.watch(eventCatalogProvider);
    final production = ref.watch(productionModeProvider);
    final identity = production ? null : ref.watch(mockIdentityRepositoryProvider);
    final encounters = ref.watch(encountersForCurrentUserProvider);
    final incomingRequests = ref.watch(incomingConnectionRequestsProvider);
    final connections = ref.watch(connectionsProvider);
    final conversations = ref.watch(chatConversationsProvider);
    void openEvent(Event event) => context.go(
      AppRoutes.eventDetails(event.id, origin: EventDetailsOrigin.home),
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
                      onFinish: () => context.go(AppRoutes.createProfile),
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
          const HomeWelcomeCard(),
          const SizedBox(height: AppSpacing.xxl),
          HomeEventSection(
            title: 'Events near you',
            events: nearbyDemoEvents,
            showDemoBadge: true,
            onSeeAll: () => context.go(AppRoutes.events),
            onEventTap: openEvent,
          ),
          const SizedBox(height: AppSpacing.xl),
          HomeEventSection(
            title: 'Popular events',
            events: popularDemoEvents,
            onSeeAll: () => context.go(AppRoutes.events),
            onEventTap: openEvent,
          ),
          const SizedBox(height: AppSpacing.xl),
          joinedIdsAsync.when(
            loading: () => const _UpcomingLoading(),
            error: (error, stack) => _UpcomingError(
              onRetry: () => ref.invalidate(joinedEventIdsProvider),
            ),
            data: (ids) {
              final joined = catalog
                  .getAll()
                  .where((event) => ids.contains(event.id))
                  .toList();
              if (joined.isEmpty) {
                return _UpcomingEmpty(
                  onExplore: () => context.go(AppRoutes.events),
                );
              }
              return HomeEventSection(
                title: 'Upcoming activities',
                events: joined,
                onSeeAll: () => context.go(AppRoutes.events),
                onEventTap: openEvent,
              );
            },
          ),
          const SizedBox(height: AppSpacing.xxl),
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
          HomeProfileCard(onViewProfile: () => context.go(AppRoutes.profile)),
          const SizedBox(height: AppSpacing.xxl),
          const HowMitzoneWorks(),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

class _UpcomingLoading extends StatelessWidget {
  const _UpcomingLoading();

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Upcoming activities'),
      SizedBox(height: AppSpacing.md),
      LinearProgressIndicator(),
    ],
  );
}

class _UpcomingEmpty extends StatelessWidget {
  const _UpcomingEmpty({required this.onExplore});
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upcoming activities',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text('No upcoming activities yet.'),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Explore events and join one to keep it here.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(onPressed: onExplore, child: const Text('Find an event')),
        ],
      ),
    );
  }
}

class _UpcomingError extends StatelessWidget {
  const _UpcomingError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upcoming activities',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text("We couldn't load your upcoming activities."),
          const SizedBox(height: AppSpacing.sm),
          TextButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
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
              "Finish your profile to get the most out of Mitzone.",
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
