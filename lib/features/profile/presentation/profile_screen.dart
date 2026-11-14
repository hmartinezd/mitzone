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
      child: profileAsync.when(
        data: (profile) => profile == null
            ? _MessageState(
                message: 'Your profile could not be found.',
                action: 'Try again',
                onPressed: () => ref.invalidate(currentProfileProvider),
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
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
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
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: Text(
                'Profile',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            IconButton(
              tooltip: 'Settings',
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => context.go(AppRoutes.settings),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _ProfileHeader(profile: profile),
        const SizedBox(height: AppSpacing.lg),
        _CompletionCard(profile: profile),
        const SizedBox(height: AppSpacing.lg),
        _AboutSection(bio: profile.bio),
        const SizedBox(height: AppSpacing.lg),
        _ChipSection(
          title: 'Interests',
          values: profile.interests,
          emptyMessage:
              'Add interests so people can quickly understand what you enjoy.',
          actionLabel: 'Add interests',
        ),
        const SizedBox(height: AppSpacing.lg),
        _ChipSection(
          title: 'Languages',
          values: profile.languages,
          emptyMessage: 'Add the languages you use to connect with others.',
          actionLabel: 'Add languages',
        ),
        const SizedBox(height: AppSpacing.lg),
        _ActivitySection(activity: activity),
        const SizedBox(height: AppSpacing.lg),
        MitzoneCard(
          onTap: () => context.go(AppRoutes.personality),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: const Row(
            children: [
              Icon(Icons.psychology_outlined),
              SizedBox(width: AppSpacing.md),
              Expanded(child: Text('Optional: describe your social style')),
              Icon(Icons.chevron_right),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
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
            radius: 32,
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
  const _CompletionCard({required this.profile});
  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final next = (profile.bio?.trim().isEmpty ?? true)
        ? 'Add a short bio so people can get to know you.'
        : profile.interests.isEmpty
        ? 'Add an interest to find something in common.'
        : profile.languages.isEmpty
        ? 'Add the languages you enjoy speaking.'
        : 'Review the details you share with other people.';
    return MitzoneCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Make it yours', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(next),
          TextButton(
            onPressed: () => context.go(AppRoutes.profileEdit),
            child: const Text('Review profile details'),
          ),
        ],
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
        onPressed: () => context.go(AppRoutes.profileEdit),
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
