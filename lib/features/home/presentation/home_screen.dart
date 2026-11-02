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
import 'widgets/home_discovery.dart';
import 'widgets/home_social_summary.dart';
import '../../encounters/presentation/foreground_presence_card.dart';
import 'home_activity_priority.dart';

// Keep the family key stable while discovery itself changes async state.
// A fresh Set in build would subscribe to a new request on every completion.
final homeDiscoveryInterestsProvider = Provider<Set<String>>((ref) {
  final interests = ref.watch(
    currentProfileProvider.select((profile) => profile.value?.interests),
  );
  return interests?.toSet() ?? const <String>{};
});

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
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        cardTheme: theme.cardTheme.copyWith(color: const Color(0xFF101B2B)),
        textButtonTheme: TextButtonThemeData(
          style: theme.textButtonTheme.style?.copyWith(
            minimumSize: const WidgetStatePropertyAll(Size(0, 48)),
          ),
        ),
      ),
      child: MitzonePageBody(
        backgroundDecoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF070D15), Color(0xFF0B1423)],
          ),
        ),
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
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 230),
              child: Text(
                'Where will you be?',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontSize: 42,
                  fontWeight: FontWeight.w700,
                  height: 1.06,
                  letterSpacing: -1.35,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Go somewhere. Be present. Mitzone does the rest.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: const Color(0xFFA6B3C4),
                height: 1.45,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            HomeDiscovery(interests: interests),
            const SizedBox(height: AppSpacing.xxl),
            const ForegroundPresenceCard(),
            const SizedBox(height: AppSpacing.xxl),
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
            child: const Text('Finish now'),
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
                  "Complete your profile to get the most out of Mitzone.",
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
