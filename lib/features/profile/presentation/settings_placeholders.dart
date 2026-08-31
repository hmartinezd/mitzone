import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/mitzone_page_body.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/identity/identity_providers.dart';
import '../../blocking/data/block_providers.dart';
import '../domain/user_profile.dart';
import 'widgets/profile_avatar.dart';
import '../../../core/auth/auth_providers.dart';
import '../data/profile_providers.dart';

class AccountSettingsScreen extends ConsumerWidget {
  const AccountSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return MitzonePageBody(
      title: 'Account',
      onBack: () => context.pop(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account sign-in is not enabled in this build.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          ListTile(
            title: const Text('Sign out'),
            subtitle: Text(
              ref.watch(productionModeProvider)
                  ? 'End this session'
                  : 'Authentication deferred',
            ),
            enabled: ref.watch(productionModeProvider),
            onTap: () async {
              await ref.read(authRepositoryProvider)?.signOut();
              ref.invalidate(authSessionProvider);
              ref.invalidate(currentProfileProvider);
              if (context.mounted) context.go('/login');
            },
          ),
          ListTile(
            title: Text(
              'Delete account',
              style: TextStyle(
                color: theme.colorScheme.error.withValues(alpha: 0.5),
              ),
            ),
            subtitle: const Text('Authentication deferred'),
            enabled: false,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class PrivacySettingsScreen extends ConsumerWidget {
  const PrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MitzonePageBody(
      title: 'Privacy',
      onBack: () => context.pop(),
      child: ref
          .watch(blockedUsersProvider)
          .when(
            data: (ids) => Column(
              children: [
                for (final id in ids)
                  ListTile(
                    leading: ProfileAvatar(
                      displayName: MockUsers.all
                          .firstWhere(
                            (u) => u.id == id,
                            orElse: () => UserProfile(id: id, displayName: id),
                          )
                          .displayName,
                      radius: 20,
                    ),
                    title: Text(
                      MockUsers.all
                          .firstWhere(
                            (u) => u.id == id,
                            orElse: () => UserProfile(id: id, displayName: id),
                          )
                          .displayName,
                    ),
                    trailing: TextButton(
                      onPressed: () async {
                        await ref
                            .read(blockRepositoryProvider)
                            .unblock(
                              blockerUserId: ref
                                  .read(mockIdentityRepositoryProvider)
                                  .currentUser
                                  .id,
                              blockedUserId: id,
                            );
                        ref.invalidate(blockedUsersProvider);
                      },
                      child: const Text('Unblock'),
                    ),
                  ),
              ],
            ),
            loading: () => const CircularProgressIndicator(),
            error: (_, _) => const Text('Privacy controls unavailable.'),
          ),
    );
  }
}

class NotificationsSettingsScreen extends StatelessWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MitzonePageBody(
      title: 'Notifications',
      onBack: () => context.pop(),
      child: const Text(
        'Notification settings will be available in a future update.',
      ),
    );
  }
}

class TermsSettingsScreen extends StatelessWidget {
  const TermsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MitzonePageBody(
      title: 'Terms & Conditions',
      onBack: () => context.pop(),
      child: const Text('Terms & Conditions will be available before release.'),
    );
  }
}

class PrivacyPolicySettingsScreen extends StatelessWidget {
  const PrivacyPolicySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MitzonePageBody(
      title: 'Privacy Policy',
      onBack: () => context.pop(),
      child: const Text('Privacy Policy will be available before release.'),
    );
  }
}
