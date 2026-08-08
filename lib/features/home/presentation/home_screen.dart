import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/mitzone_page_body.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/router/app_routes.dart';
import '../../profile/data/profile_providers.dart';
import '../../events/data/demo_events.dart';
import 'widgets/home_header.dart';
import 'widgets/home_welcome_card.dart';
import 'widgets/home_event_section.dart';
import 'widgets/home_matches_card.dart';
import 'widgets/home_profile_card.dart';
import 'widgets/how_mitzone_works.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);

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
          ),
          const SizedBox(height: AppSpacing.xl),
          HomeEventSection(
            title: 'Popular events',
            events: popularDemoEvents,
            onSeeAll: () => context.go(AppRoutes.events),
          ),
          const SizedBox(height: AppSpacing.xl),
          HomeEventSection(
            title: 'Upcoming activities',
            events: upcomingDemoEvents,
            onSeeAll: () => context.go(AppRoutes.events),
          ),
          const SizedBox(height: AppSpacing.xxl),
          HomeMatchesCard(
            onExploreEvents: () => context.go(AppRoutes.events),
            onScanQR: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('QR scanning is coming soon.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
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
