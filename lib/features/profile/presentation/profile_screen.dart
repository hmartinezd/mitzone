import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/mitzone_page_body.dart';
import '../../../shared/widgets/mitzone_card.dart';
import '../../../shared/widgets/mitzone_loading_indicator.dart';
import '../../../shared/widgets/mitzone_button.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/router/app_routes.dart';
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
        data: (profile) {
          if (profile == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Your profile could not be found.'),
                  const SizedBox(height: AppSpacing.md),
                  MitzoneButton(
                    text: 'Finish your profile',
                    onPressed: () => context.go(AppRoutes.createProfile),
                  ),
                ],
              ),
            );
          }
          return _ProfileContent(profile: profile);
        },
        loading: () => const Center(child: MitzoneLoadingIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("We couldn't load your profile."),
              const SizedBox(height: AppSpacing.md),
              MitzoneButton(
                text: 'Try again',
                onPressed: () => ref.invalidate(currentProfileProvider),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({required this.profile});
  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.lg),
        Center(
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
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton.icon(
                onPressed: () => context.go(AppRoutes.profileEdit),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit profile'),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        _CompletionCard(percentage: profile.completionPercentage),
        const SizedBox(height: AppSpacing.xxl),
        _ProfileDetailsSection(profile: profile),
        const SizedBox(height: AppSpacing.xxl),
        _SettingsAction(),
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }
}

class _CompletionCard extends StatelessWidget {
  const _CompletionCard({required this.percentage});
  final int percentage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: 'Profile $percentage percent complete',
      child: MitzoneCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              'Add optional details when you\'re ready.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileDetailsSection extends StatelessWidget {
  const _ProfileDetailsSection({required this.profile});
  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                profile.completionPercentage < 100
                    ? 'Complete your profile'
                    : 'About you',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton(
              onPressed: () => context.go(AppRoutes.profileDetails),
              child: const Text('Edit details'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        MitzoneCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              _DetailRow(label: 'Bio', value: profile.bio, icon: Icons.notes),
              const Divider(),
              _DetailRow(
                label: 'City',
                value: profile.city,
                icon: Icons.location_on_outlined,
              ),
              const Divider(),
              _DetailRow(
                label: 'Interests',
                value: profile.interests.isEmpty
                    ? null
                    : profile.interests.join(', '),
                icon: Icons.interests_outlined,
              ),
              const Divider(),
              _DetailRow(
                label: 'Languages',
                value: profile.languages.isEmpty
                    ? null
                    : profile.languages.join(', '),
                icon: Icons.language_outlined,
              ),
              const Divider(),
              _DetailRow(
                label: 'Connection Goal',
                value: profile.connectionGoal?.name.toUpperCase(),
                icon: Icons.handshake_outlined,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String? value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value ?? 'Not added yet',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: value == null
                        ? theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.5,
                          )
                        : theme.colorScheme.onSurface,
                    fontStyle: value == null ? FontStyle.italic : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsAction extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.go(AppRoutes.settings),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.settings_outlined, color: theme.colorScheme.primary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'Settings',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
