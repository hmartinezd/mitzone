import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/mitzone_page_body.dart';
import '../../../app/theme/app_spacing.dart';

class AccountSettingsScreen extends StatelessWidget {
  const AccountSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
          // We don't expose UUID or other internal IDs here as per requirements.
        ],
      ),
    );
  }
}

class PrivacySettingsScreen extends StatelessWidget {
  const PrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MitzonePageBody(
      title: 'Privacy',
      onBack: () => context.pop(),
      child: const Text('Privacy controls are coming in a later phase.'),
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
