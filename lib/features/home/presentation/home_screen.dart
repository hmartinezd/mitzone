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
import '../../profile/data/profile_repository.dart';
import '../../profile/domain/user_profile.dart';
import '../../discovery/data/discovery_providers.dart';
import '../../discovery/data/discovery_location_provider.dart';
import '../../events/domain/event.dart';
import '../../events/data/event_providers.dart';
import 'widgets/home_header.dart';
import 'widgets/home_discovery.dart';
import 'widgets/home_social_summary.dart';
import '../../encounters/presentation/foreground_presence_card.dart';
import 'home_activity_priority.dart';
import 'widgets/shared_moments_hero.dart';

// Keep the family key stable while discovery itself changes async state.
// A fresh Set in build would subscribe to a new request on every completion.
final homeDiscoveryInterestsProvider = Provider<Set<String>>((ref) {
  final interests = ref.watch(
    currentProfileProvider.select((profile) => profile.value?.interests),
  );
  return interests?.toSet() ?? const <String>{};
});

// Account-scoped, authorized public profiles only; denied/missing profiles remain anonymous.
final homeParticipantProfilesProvider = FutureProvider<List<UserProfile>>((
  ref,
) async {
  if (!ref.watch(productionModeProvider)) return const [];
  final me = await ref.watch(currentUserIdProvider.future);
  final encounters = ref.watch(encountersForCurrentUserProvider).value ?? [];
  final conversations = ref.watch(chatConversationsProvider).value ?? [];
  final ids = <String>{
    for (final encounter in encounters) encounter.otherUserId,
    for (final conversation in conversations)
      if (conversation.userAId == me)
        conversation.userBId
      else
        conversation.userAId,
  }..remove(me);
  if (ids.isEmpty) return const [];
  try {
    return (await ref.watch(profileRepositoryProvider).loadProfilesByIds(ids))
        .values
        .toList();
  } catch (_) {
    return const [];
  }
});

List<Event> upcomingJoinedActivities(
  Set<String> ids,
  Iterable<Event> events,
  DateTime now,
) {
  final result = events
      .where(
        (event) =>
            ids.contains(event.id) &&
            event.title.trim().isNotEmpty &&
            event.venue.trim().isNotEmpty &&
            event.timeLabel.trim().isNotEmpty &&
            event.startsAt != null &&
            event.startsAt!.isAfter(now),
      )
      .toList();
  result.sort((a, b) => a.startsAt!.compareTo(b.startsAt!));
  return result.take(3).toList();
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);
    final catalog = ref.watch(eventCatalogProvider);
    final interests = ref.watch(homeDiscoveryInterestsProvider);
    final production = ref.watch(productionModeProvider);
    final identity = production
        ? null
        : ref.watch(mockIdentityRepositoryProvider);
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
    final participants = ref.watch(homeParticipantProfilesProvider);
    // Watching the provider makes catalog replacement reactive on discovery completion.
    final nearbyEvents = ref.watch(nearbyEventsProvider);
    final joined = ref.watch(joinedEventIdsProvider);
    final upcoming = upcomingJoinedActivities(
      joined.value ?? {},
      {
        ...{for (final event in catalog.getAll()) event.id: event},
        ...{
          for (final event in nearbyEvents.value ?? <Event>[]) event.id: event,
        },
      }.values,
      ref.watch(utcNowProvider)(),
    );
    final actionable =
        (incomingRequests.value?.isNotEmpty ?? false) ||
        (conversations.value?.isNotEmpty ?? false);
    final social = HomeSocialSummary(
      encounters: encounters,
      incomingRequests: incomingRequests,
      connections: connections,
      conversations: conversations,
      currentUserId: production
          ? (ref.watch(currentUserIdProvider).value ?? '')
          : identity!.currentUser.id,
      users: production ? (participants.value ?? []) : identity!.users,
      eventCatalog: catalog,
      onExploreEvents: () => context.go(AppRoutes.explore),
      onViewMatches: () => context.go(AppRoutes.nearby),
      onOpenChat: () => context.push(AppRoutes.chat),
      onOpenConversation: (id) => context.push('${AppRoutes.chat}/$id'),
      onRetryEncounters: () => ref.invalidate(encountersForCurrentUserProvider),
    );
    Future<void> refresh() async {
      ref.invalidate(discoveryLocationProvider);
      ref.invalidate(currentProfileProvider);
      ref.invalidate(encountersForCurrentUserProvider);
      ref.invalidate(incomingConnectionRequestsProvider);
      ref.invalidate(connectionsProvider);
      ref.invalidate(chatConversationsProvider);
      ref.invalidate(joinedEventIdsProvider);
      ref.invalidate(homeParticipantProfilesProvider);
      ref.invalidate(nearbyDiscoveryProvider(interests));
      ref.invalidate(nearbyEventsProvider);
      // Each provider retains its own honest error state; refresh always settles.
      await Future.wait<void>(
        [
          ref.read(currentProfileProvider.future).then((_) {}),
          ref.read(encountersForCurrentUserProvider.future).then((_) {}),
          ref.read(incomingConnectionRequestsProvider.future).then((_) {}),
          ref.read(connectionsProvider.future).then((_) {}),
          ref.read(chatConversationsProvider.future).then((_) {}),
          ref.read(joinedEventIdsProvider.future).then((_) {}),
          ref.read(nearbyDiscoveryProvider(interests).future).then((_) {}),
          ref.read(nearbyEventsProvider.future).then((_) {}),
        ].map((task) => task.catchError((Object _) {})),
      );
    }

    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: refresh,
      child: MitzonePageBody(
        backgroundDecoration: BoxDecoration(color: theme.colorScheme.surface),
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
            const SizedBox(height: AppSpacing.xxl),
            if (TickerMode.valuesOf(context).enabled)
              const ForegroundPresenceCard(),
            const SizedBox(height: AppSpacing.lg),
            if (actionable) ...[social, const SizedBox(height: AppSpacing.lg)],
            const SharedMomentsHero(),
            const SizedBox(height: AppSpacing.lg),
            if (priority == HomeActivityPriority.lowActivity &&
                encounters.hasValue &&
                incomingRequests.hasValue &&
                connections.hasValue &&
                conversations.hasValue) ...[
              QuietMomentsCard(onExplore: () => context.go(AppRoutes.explore)),
              const SizedBox(height: AppSpacing.lg),
            ],
            if (upcoming.isNotEmpty) ...[
              Text(
                'Your upcoming activities',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              for (final event in upcoming)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(event.title),
                  subtitle: Text('${event.venue} · ${event.timeLabel}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go(
                    AppRoutes.eventDetails(
                      event.id,
                      origin: EventDetailsOrigin.home,
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.lg),
            ],
            HomeDiscovery(interests: interests),
            const SizedBox(height: AppSpacing.xxl),
            if (!actionable &&
                (priority != HomeActivityPriority.lowActivity ||
                    encounters.hasError ||
                    incomingRequests.hasError ||
                    connections.hasError ||
                    conversations.hasError)) ...[
              social,
              const SizedBox(height: AppSpacing.xxl),
            ],
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final action = TextButton(
            onPressed: onRetry,
            child: const Text('Try again'),
          );
          final stackAction =
              constraints.maxWidth / MediaQuery.textScalerOf(context).scale(1) <
              300;
          final message = Row(
            children: [
              Icon(Icons.error_outline, color: theme.colorScheme.error),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  "We couldn't load your profile.",
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              if (!stackAction) action,
            ],
          );
          return stackAction
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    message,
                    Align(alignment: Alignment.centerRight, child: action),
                  ],
                )
              : message;
        },
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final action = TextButton(
            onPressed: onFinish,
            child: const Text('Reload profile'),
          );
          final stackAction =
              constraints.maxWidth / MediaQuery.textScalerOf(context).scale(1) <
              300;
          final message = Row(
            children: [
              Icon(Icons.info_outline, color: theme.colorScheme.primary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  "Your profile is not available yet. Try loading it again.",
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              if (!stackAction) action,
            ],
          );
          return stackAction
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    message,
                    Align(alignment: Alignment.centerRight, child: action),
                  ],
                )
              : message;
        },
      ),
    );
  }
}
