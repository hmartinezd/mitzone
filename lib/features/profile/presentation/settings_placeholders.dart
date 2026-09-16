import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/mitzone_page_body.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/identity/identity_providers.dart';
import '../../../core/identity/mock_identity_repository.dart';
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
            'Manage your Mitzone account.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          if (ref.watch(productionModeProvider)) ListTile(
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
          if (ref.watch(productionModeProvider)) ListTile(
            title: Text(
              'Delete account',
              style: TextStyle(
                color: theme.colorScheme.error.withValues(alpha: 0.5),
              ),
            ),
            subtitle: const Text('Permanently remove your account and data'),
            onTap: () => _confirmDelete(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: const Text('Delete account?'),
      content: const Text('This permanently deletes your account and associated data.'),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete'))],
    ));
    if (confirmed != true || !context.mounted) return;
    try { await ref.read(authRepositoryProvider)!.deleteAccount(); ref.invalidate(authSessionProvider); ref.invalidate(currentProfileProvider); if (context.mounted) context.go('/login'); }
    catch (_) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account deletion failed. Please try again.'))); }
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
      child: const ListTile(
        leading: Icon(Icons.notifications_outlined),
        title: Text('Device notifications'),
        subtitle: Text('Push permission is requested when the signed-in app is ready.'),
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
      child: const SingleChildScrollView(child: Text('''Mitzone Terms of Service\n\nEligibility: Mitzone is intended for people who meet the minimum age required in their location. Minors may not use the service where prohibited.\n\nYou are responsible for your account and for content you submit. Do not impersonate others, harass or threaten people, share unlawful or harmful content, misuse the service, or attempt unauthorized access. Profiles and messages are user-generated and may be inaccurate.\n\nUse Report and Block tools for safety concerns. Mitzone may restrict or terminate accounts that violate these terms or create risk. You may delete your account from Settings.\n\nMitzone is an early-stage service provided as available; features may change or be unavailable. To the extent permitted by law, Mitzone disclaims warranties and limits liability for use of the service.\n\nYou retain rights to your content and grant Mitzone the limited license needed to operate the service. Final legal entity, governing law, contact details, and minimum-age policy require owner/legal review before release.''')),
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
      child: const SingleChildScrollView(child: Text('''Mitzone MVP Privacy Policy\n\nMitzone currently uses Supabase for authentication and profile data, and Firebase Analytics, Crashlytics, and Cloud Messaging for observability and notifications. We do not sell personal data.\n\nWe process email authentication data; profile information you choose to provide; event participation, foreground presence, coarse place context and bounded time data used to derive nearby/shared-context discovery; connections, requests, conversations and messages; blocks and reports; device tokens for push delivery; and limited analytics/crash diagnostics. We use these to provide accounts, profiles, discovery, social features, safety tools, notifications, reliability and aggregate product measurement.\n\nPresence is explicit, foreground-only and user-controlled. When active, current location may be resolved to coarse place context for a limited presence record. Mitzone does not request background location, store raw location history, or expose exact location to other users.\n\nSupabase stores the authenticated account/profile and configured backend records. Firebase receives analytics events, crash diagnostics and push-device identifiers as applicable. Analytics excludes message contents, exact location, tokens, credentials, contact details and unnecessary profile PII.\n\nYou can control whether to activate presence, deny location permission, stop presence, manage notifications through the device, block users, report concerns, and delete your account. Account deletion removes the auth account and cascaded user-owned records supported by the current schema, including profile, relationships, conversations/messages and device tokens. Local/demo records may remain on the device until app data is cleared.\n\nRetention follows current storage behavior; final retention schedules and legal-contact details require review before public release. Mitzone is not intended for children below the final published minimum age. Material policy changes will be communicated through an updated policy and appropriate in-app or release communication.\n\nFinal entity name, privacy/support email, address, production policy URL, jurisdictions and user-rights request process must be supplied by the owner and legal reviewer.''')),
    );
  }
}
