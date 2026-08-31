import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../shared/widgets/mitzone_button.dart';
import '../../../shared/widgets/mitzone_card.dart';
import '../../../shared/widgets/mitzone_loading_indicator.dart';
import '../../../shared/widgets/mitzone_page_body.dart';
import '../../events/data/event_providers.dart';
import '../data/profile_providers.dart';
import '../domain/user_profile.dart';
import 'widgets/profile_avatar.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);
    return MitzonePageBody(
      title: 'Profile',
      child: profileAsync.when(
        data: (profile) => profile == null
            ? _MessageState(
                message: 'Your profile could not be found.',
                action: 'Finish your profile',
                onPressed: () => context.go(AppRoutes.createProfile),
              )
            : _ProfileContent(profile: profile),
        loading: () => const Center(child: MitzoneLoadingIndicator()),
        error: (error, stack) => _MessageState(
          message: "We couldn't load your profile.",
          action: 'Try again',
          onPressed: () => ref.invalidate(currentProfileProvider),
        ),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.message,
    required this.action,
    required this.onPressed,
  });
  final String message;
  final String action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.md),
          MitzoneButton(text: action, onPressed: onPressed, fullWidth: false),
        ],
      ),
    ),
  );
}

class _ProfileContent extends ConsumerWidget {
  const _ProfileContent({required this.profile});
  final UserProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(eventCatalogProvider);
    final activity = ref
        .watch(joinedEventIdsProvider)
        .whenData(
          (ids) => ids.where((id) => catalog.getById(id) != null).toSet(),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.lg),
        _ProfileHeader(profile: profile),
        const SizedBox(height: AppSpacing.xxl),
        _CompletionCard(percentage: profile.completionPercentage),
        const SizedBox(height: AppSpacing.xxl),
        _AboutSection(bio: profile.bio),
        const SizedBox(height: AppSpacing.xxl),
        _ChipSection(
          title: 'Interests',
          values: profile.interests,
          emptyMessage:
              'Add interests so people can quickly understand what you enjoy.',
          actionLabel: 'Add interests',
        ),
        const SizedBox(height: AppSpacing.xxl),
        _ChipSection(
          title: 'Languages',
          values: profile.languages,
          emptyMessage: 'Add the languages you use to connect with others.',
          actionLabel: 'Add languages',
        ),
        const SizedBox(height: AppSpacing.xxl),
        _ActivitySection(activity: activity),
        const SizedBox(height: AppSpacing.xxl),
        MitzoneCard(
          onTap: () => context.go(AppRoutes.personality),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: const Row(children: [Icon(Icons.psychology_outlined), SizedBox(width: AppSpacing.md), Expanded(child: Text('Optional: describe your social style')), Icon(Icons.chevron_right)]),
        ),
        const SizedBox(height: AppSpacing.xxl),
        const _SettingsAction(),
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile});
  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final city = profile.city?.trim();
    final goal = _connectionGoalLabel(profile.connectionGoal);
    return Center(
      child: Column(
        children: [
          ProfileAvatar(
            displayName: profile.displayName,
            avatarUri: profile.avatarUri,
            radius: 50,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            profile.displayName,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (city != null && city.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              city,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (goal != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Chip(
              avatar: const Icon(Icons.handshake_outlined, size: 18),
              label: Text(goal),
              visualDensity: VisualDensity.compact,
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          TextButton.icon(
            onPressed: () => context.go(AppRoutes.profileEdit),
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Edit profile'),
          ),
        ],
      ),
    );
  }
}

String? _connectionGoalLabel(ConnectionGoal? goal) => switch (goal) {
  ConnectionGoal.social => 'Social',
  ConnectionGoal.professional => 'Professional',
  ConnectionGoal.both => 'Social + Professional',
  null => null,
};

class _CompletionCard extends StatelessWidget {
  const _CompletionCard({required this.percentage});
  final int percentage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final complete = percentage >= 100;
    return Semantics(
      label: 'Profile $percentage percent complete',
      child: MitzoneCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Your profile',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '$percentage%',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ExcludeSemantics(
              child: LinearProgressIndicator(
                value: percentage / 100,
                borderRadius: BorderRadius.circular(4),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              complete
                  ? 'Your profile is complete. You can update your details anytime.'
                  : 'Add a few more details to help people understand who you are.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (!complete) ...[
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: () => context.go(AppRoutes.profileDetails),
                child: const Text('Complete profile'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AboutSection extends StatelessWidget {
  const _AboutSection({required this.bio});
  final String? bio;

  @override
  Widget build(BuildContext context) {
    final value = bio?.trim();
    return _Section(
      title: 'About',
      child: value != null && value.isNotEmpty
          ? Text(value)
          : const _ProgressiveEmptyState(
              message: 'Tell people a little about yourself.',
              actionLabel: 'Add bio',
            ),
    );
  }
}

class _ChipSection extends StatelessWidget {
  const _ChipSection({
    required this.title,
    required this.values,
    required this.emptyMessage,
    required this.actionLabel,
  });
  final String title;
  final List<String> values;
  final String emptyMessage;
  final String actionLabel;

  @override
  Widget build(BuildContext context) => _Section(
    title: title,
    child: values.isEmpty
        ? _ProgressiveEmptyState(
            message: emptyMessage,
            actionLabel: actionLabel,
          )
        : Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [for (final value in values) Chip(label: Text(value))],
          ),
  );
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        child,
      ],
    );
  }
}

class _ProgressiveEmptyState extends StatelessWidget {
  const _ProgressiveEmptyState({
    required this.message,
    required this.actionLabel,
  });
  final String message;
  final String actionLabel;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(message),
      const SizedBox(height: AppSpacing.xs),
      TextButton(
        onPressed: () => context.go(AppRoutes.profileDetails),
        child: Text(actionLabel),
      ),
    ],
  );
}

class _ActivitySection extends ConsumerWidget {
  const _ActivitySection({required this.activity});
  final AsyncValue<Set<String>> activity;

  @override
  Widget build(BuildContext context, WidgetRef ref) => _Section(
    title: 'My activity',
    child: MitzoneCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: activity.when(
        loading: () => const Row(
          children: [
            MitzoneLoadingIndicator(compact: true),
            SizedBox(width: AppSpacing.md),
            Expanded(child: Text('Loading your activity…')),
          ],
        ),
        error: (error, stack) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("We couldn't load your activity."),
            const SizedBox(height: AppSpacing.xs),
            TextButton(
              onPressed: () => ref.invalidate(joinedEventIdsProvider),
              child: const Text('Try again'),
            ),
          ],
        ),
        data: (joinedIds) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(child: Text('Joined events')),
                Text(
                  '${joinedIds.length}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton.icon(
              onPressed: () => context.go(AppRoutes.events),
              icon: const Icon(Icons.calendar_month_outlined, size: 18),
              label: const Text('View events'),
            ),
          ],
        ),
      ),
    ),
  );
}

class _SettingsAction extends StatelessWidget {
  const _SettingsAction();

  @override
  Widget build(BuildContext context) => MitzoneCard(
    onTap: () => context.go(AppRoutes.settings),
    padding: const EdgeInsets.all(AppSpacing.lg),
    child: Row(
      children: [
        Icon(
          Icons.settings_outlined,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: AppSpacing.md),
        const Expanded(child: Text('Settings')),
        const Icon(Icons.chevron_right),
      ],
    ),
  );
}
