import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/mitzone_page_body.dart';
import '../../../shared/widgets/mitzone_card.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/router/app_routes.dart';
import '../../../core/identity/identity_providers.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MitzonePageBody(
      title: 'Settings',
      onBack: () => context.pop(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.lg),
          _SettingsSection(
            title: 'General',
            items: [
              _SettingsItem(
                icon: Icons.person_outline,
                title: 'Account',
                onTap: () => context.go(AppRoutes.settingsAccount),
              ),
              _SettingsItem(
                icon: Icons.lock_outline,
                title: 'Privacy',
                onTap: () => context.go(AppRoutes.settingsPrivacy),
              ),
              _SettingsItem(
                icon: Icons.notifications_none,
                title: 'Notifications',
                onTap: () => context.go(AppRoutes.settingsNotifications),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          const _DeveloperUserSection(),
          const SizedBox(height: AppSpacing.xl),
          _SettingsSection(
            title: 'About',
            items: [
              _SettingsItem(
                icon: Icons.description_outlined,
                title: 'Terms & Conditions',
                onTap: () => context.go(AppRoutes.settingsTerms),
              ),
              _SettingsItem(
                icon: Icons.policy_outlined,
                title: 'Privacy Policy',
                onTap: () => context.go(AppRoutes.settingsPrivacyPolicy),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

class _DeveloperUserSection extends ConsumerWidget {
  const _DeveloperUserSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(mockIdentityRepositoryProvider);
    return _SettingsSection(
      title: 'Developer',
      items: [
        _SettingsItem(
          icon: Icons.developer_mode_outlined,
          title: 'Current User',
          subtitle: '${repository.currentUser.displayName}  >',
          onTap: () => _showUserPicker(context, ref),
        ),
      ],
    );
  }

  Future<void> _showUserPicker(BuildContext context, WidgetRef ref) async {
    final repository = ref.read(mockIdentityRepositoryProvider);
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const ListTile(title: Text('Switch mock user')),
          for (final user in repository.users)
            RadioListTile<String>(value: user.id, groupValue: repository.currentUser.id, title: Text(user.displayName), onChanged: (id) => Navigator.pop(context, id)),
        ]),
      ),
    );
    if (selected != null) await repository.setCurrentUser(selected);
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.items});

  final String title;
  final List<_SettingsItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          child: Text(
            title.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        MitzoneCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                items[i],
                if (i < items.length - 1) const Divider(height: 1, indent: 56),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsItem extends StatelessWidget {
  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
      ),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      minVerticalPadding: 16, // Ensure 48px height even with small text
    );
  }
}
