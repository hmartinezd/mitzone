import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/mitzone_page_body.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/identity/current_user_provider.dart';
import '../../blocking/data/block_providers.dart';
import 'widgets/profile_avatar.dart';
import '../../../core/auth/auth_providers.dart';
import '../data/profile_providers.dart';
import '../data/public_peer_profiles.dart';
import '../../notifications/data/notification_settings_provider.dart';
import '../../personality/data/personality_providers.dart';

class AccountSettingsScreen extends ConsumerStatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  ConsumerState<AccountSettingsScreen> createState() => _AccountSettingsState();
}

class _AccountSettingsState extends ConsumerState<AccountSettingsScreen> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    ref.watch(authSessionProvider);
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
          if (ref.watch(productionModeProvider))
            ListTile(
              title: const Text('Sign out'),
              subtitle: Text(
                ref.watch(productionModeProvider)
                    ? 'End this session'
                    : 'Authentication deferred',
              ),
              enabled: !_busy,
              onTap: _busy ? null : _signOut,
            ),
          if (ref.watch(productionModeProvider))
            ListTile(
              title: Text(
                'Delete account',
                style: TextStyle(color: theme.colorScheme.error),
              ),
              subtitle: const Text('Permanently remove your account and data'),
              enabled: !_busy,
              onTap: _busy ? null : () => _confirmDelete(context, ref),
            ),
        ],
      ),
    );
  }

  Future<void> _signOut() async {
    setState(() => _busy = true);
    try {
      final userId = await ref.read(currentUserIdProvider.future);
      await ref.read(personalityDraftStoreProvider).clear(userId);
      await ref.read(authRepositoryProvider)!.signOut();
      if (!mounted) return;
      ref.invalidate(authSessionProvider);
      ref.invalidate(currentProfileProvider);
      context.go('/login');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not finish signing out. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This permanently deletes your account and associated data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    setState(() => _busy = true);
    try {
      final userId = await ref.read(currentUserIdProvider.future);
      // Finish device cleanup before the destructive server operation so a
      // storage failure can never be reported as a failed server deletion.
      await ref.read(personalityDraftStoreProvider).clear(userId);
      await ref.read(authRepositoryProvider)!.deleteAccount();
      if (!context.mounted) return;
      ref.invalidate(authSessionProvider);
      ref.invalidate(currentProfileProvider);
      if (context.mounted) context.go('/login');
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not complete account deletion. Please try again.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class PrivacySettingsScreen extends ConsumerStatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  ConsumerState<PrivacySettingsScreen> createState() => _PrivacySettingsState();
}

class _PrivacySettingsState extends ConsumerState<PrivacySettingsScreen> {
  final Set<String> _busy = {};

  @override
  Widget build(BuildContext context) {
    final blocked = ref.watch(blockedUsersProvider);
    return MitzonePageBody(
      title: 'Blocked people',
      onBack: () => context.pop(),
      child: blocked.when(
        data: (ids) {
          if (ids.isEmpty) {
            return const ListTile(
              leading: Icon(Icons.shield_outlined),
              title: Text('No blocked people'),
              subtitle: Text(
                'People you block appear here. You can block someone from their profile.',
              ),
            );
          }
          final profiles = ref.watch(
            publicPeerProfilesProvider(publicPeerIdsKey(ids)),
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Blocked people cannot interact with you. Unblocking does not restore a previous connection.',
              ),
              if (profiles.hasError)
                TextButton(
                  onPressed: () => ref.invalidate(publicPeerProfilesProvider),
                  child: const Text('Retry names'),
                ),
              for (final id in ids)
                Builder(
                  builder: (context) {
                    final profile = profiles.value?[id];
                    final name = profile?.displayName.trim();
                    final identifiable = name != null && name.isNotEmpty;
                    final label = identifiable
                        ? name
                        : profiles.isLoading
                        ? 'Loading identity…'
                        : 'Identity unavailable';
                    return ListTile(
                      leading: ProfileAvatar(
                        displayName: identifiable ? name : '?',
                        radius: 20,
                      ),
                      title: Text(label),
                      subtitle: identifiable
                          ? null
                          : Text(
                              'Reference: $id\nTheir name is not available. Keep them blocked unless you recognize this reference.',
                            ),
                      trailing: TextButton(
                        onPressed: profiles.isLoading || _busy.contains(id)
                            ? null
                            : () => _confirmUnblock(
                                id,
                                identifiable ? name : null,
                              ),
                        child: Text(
                          _busy.contains(id)
                              ? 'Unblocking…'
                              : identifiable
                              ? 'Unblock'
                              : 'Review',
                        ),
                      ),
                    );
                  },
                ),
              if (profiles.value != null &&
                  ids.any(
                    (id) =>
                        !(profiles.value?[id]?.displayName.trim().isNotEmpty ??
                            false),
                  ))
                TextButton(
                  onPressed: () => ref.invalidate(publicPeerProfilesProvider),
                  child: const Text('Retry identities'),
                ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
            semanticsLabel: 'Loading blocked people',
          ),
        ),
        error: (_, _) => Column(
          children: [
            const Text(
              'We could not load blocked people. Your blocks have not changed.',
            ),
            TextButton(
              onPressed: () => ref.invalidate(blockedUsersProvider),
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmUnblock(String id, String? name) async {
    if (_busy.contains(id)) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(name == null ? 'Review blocked account' : 'Unblock $name?'),
        content: Text(
          '${name == null ? 'Name unavailable. Account reference: $id\n\nOnly unblock if you recognize this reference. Otherwise choose Keep blocked.\n\n' : ''}This allows future interaction again. It does not restore your previous connection or conversation.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep blocked'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Unblock'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || _busy.contains(id)) return;
    setState(() => _busy.add(id));
    try {
      final blocker = await ref.read(currentUserIdProvider.future);
      await ref
          .read(blockRepositoryProvider)
          .unblock(blockerUserId: blocker, blockedUserId: id);
      ref.invalidate(blockedUsersProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              name == null ? 'Selected account unblocked.' : '$name unblocked.',
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not unblock this person. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy.remove(id));
    }
  }
}

class NotificationsSettingsScreen extends ConsumerStatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  ConsumerState<NotificationsSettingsScreen> createState() =>
      _NotificationSettingsState();
}

class _NotificationSettingsState
    extends ConsumerState<NotificationsSettingsScreen>
    with WidgetsBindingObserver {
  bool _opening = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(deviceNotificationStatusProvider);
    }
  }

  @override
  Widget build(BuildContext context) => MitzonePageBody(
    title: 'Notifications',
    onBack: () => context.pop(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ref
            .watch(deviceNotificationStatusProvider)
            .when(
              data: (status) => ListTile(
                leading: const Icon(Icons.notifications_outlined),
                title: Text(switch (status) {
                  DeviceNotificationStatus.allowed => 'Notifications allowed',
                  DeviceNotificationStatus.quiet =>
                    'Quiet notifications allowed',
                  DeviceNotificationStatus.denied => 'Notifications turned off',
                  DeviceNotificationStatus.notRequested =>
                    'Permission not requested',
                  DeviceNotificationStatus.unavailable =>
                    'Notification status unavailable',
                }),
                subtitle: const Text(
                  'Your device controls alerts. Permission does not guarantee delivery. You can still read updates in the app.',
                ),
              ),
              loading: () => const CircularProgressIndicator(
                semanticsLabel: 'Checking notification settings',
              ),
              error: (_, _) => const Text(
                'We could not read notification permission. Your settings have not changed.',
              ),
            ),
        TextButton(
          onPressed: () => ref.invalidate(deviceNotificationStatusProvider),
          child: const Text('Refresh status'),
        ),
        OutlinedButton.icon(
          onPressed: _opening ? null : _openSettings,
          icon: const Icon(Icons.settings_outlined),
          label: const Text('Open device app settings'),
        ),
        const SizedBox(height: AppSpacing.md),
        const Text(
          'Choose Notifications in the device settings. Opening settings does not change your permission.',
        ),
      ],
    ),
  );

  Future<void> _openSettings() async {
    if (_opening) return;
    setState(() => _opening = true);
    try {
      final opened = await ref
          .read(notificationSettingsGatewayProvider)
          .openSettings();
      if (!opened) throw StateError('Settings unavailable');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Open your device Settings, select Mitzone, then Notifications.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }
}

class TermsSettingsScreen extends StatelessWidget {
  const TermsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MitzonePageBody(
      title: 'Terms & Conditions',
      onBack: () => context.canPop() ? context.pop() : context.go('/login'),
      child: const _LegalCopy(
        '''Mitzone Terms of Service\n\nEligibility: Mitzone is intended for people who meet the minimum age required in their location. Minors may not use the service where prohibited.\n\nYou are responsible for your account and for content you submit. Do not impersonate others, harass or threaten people, share unlawful or harmful content, misuse the service, or attempt unauthorized access. Profiles and messages are user-generated and may be inaccurate.\n\nUse Report and Block tools for safety concerns. Mitzone may restrict or terminate accounts that violate these terms or create risk. You may delete your account from Settings.\n\nMitzone is an early-stage service provided as available; features may change or be unavailable. To the extent permitted by law, Mitzone disclaims warranties and limits liability for use of the service.\n\nYou retain rights to your content and grant Mitzone the limited license needed to operate the service. Final legal entity, governing law, contact details, and minimum-age policy require owner/legal review before release.''',
      ),
    );
  }
}

class PrivacyPolicySettingsScreen extends StatelessWidget {
  const PrivacyPolicySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MitzonePageBody(
      title: 'Privacy Policy',
      onBack: () => context.canPop() ? context.pop() : context.go('/login'),
      child: const _LegalCopy(
        '''Mitzone MVP Privacy Policy\n\nMitzone currently uses Supabase for authentication and profile data, and Firebase Analytics, Crashlytics, and Cloud Messaging for observability and notifications. Nearby discovery also sends location-based requests through our backend to Google Places and Ticketmaster. Discovery location permission does not activate shared-context presence. We do not sell personal data.\n\nWe process email authentication data; profile information you choose to provide; event participation, foreground presence, coarse place context and bounded time data used to derive nearby/shared-context discovery; connections, requests, conversations and messages; blocks and reports; device tokens for push delivery; and limited analytics/crash diagnostics. We use these to provide accounts, profiles, discovery, social features, safety tools, notifications, reliability and aggregate product measurement.\n\nPresence is explicit, foreground-only and user-controlled. When active, current coordinates are sent to our trusted backend for resolution into coarse place context for a limited presence record. Mitzone does not request background location, store raw location history, or expose exact location to other users.\n\nSupabase stores the authenticated account/profile and configured backend records. Firebase receives analytics events, crash diagnostics and push-device identifiers as applicable. Analytics excludes message contents, exact location, tokens, credentials, contact details and unnecessary profile PII.\n\nYou can control whether to activate presence, deny location permission, stop presence, manage notifications through the device, block users, report concerns, and delete your account. Account deletion removes the auth account and cascaded user-owned records supported by the current schema, including profile, relationships, conversations/messages and device tokens. Local/demo records may remain on the device until app data is cleared.\n\nRetention follows current storage behavior; final retention schedules and legal-contact details require review before public release. Mitzone is not intended for children below the final published minimum age. Material policy changes will be communicated through an updated policy and appropriate in-app or release communication.\n\nFinal entity name, privacy/support email, address, production policy URL, jurisdictions and user-rights request process must be supplied by the owner and legal reviewer.''',
      ),
    );
  }
}

class _LegalCopy extends StatelessWidget {
  const _LegalCopy(this.copy);
  final String copy;
  @override
  Widget build(BuildContext context) {
    final paragraphs = copy.split('\n\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.lg),
          child: Text(
            'Pre-release information: these documents still need owner and legal review before a public launch.',
          ),
        ),
        for (final paragraph in paragraphs)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: SelectableText(
              paragraph,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
      ],
    );
  }
}
