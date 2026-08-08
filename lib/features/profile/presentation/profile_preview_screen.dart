import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/mitzone_page_body.dart';
import '../../../app/theme/app_spacing.dart';
import '../data/profile_providers.dart';

class ProfilePreviewScreen extends ConsumerWidget {
  const ProfilePreviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profileAsync = ref.watch(currentProfileProvider);

    return MitzonePageBody(
      title: 'Profile',
      child: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Profile not found.'));
          }

          return Column(
            children: [
              const SizedBox(height: AppSpacing.xxl),
              CircleAvatar(
                radius: 60,
                backgroundColor: theme.colorScheme.surfaceContainer,
                backgroundImage: profile.avatarUri != null
                    ? FileImage(File(profile.avatarUri!))
                    : null,
                child: profile.avatarUri == null
                    ? Icon(
                        Icons.person_outline,
                        size: 60,
                        color: theme.colorScheme.onSurfaceVariant,
                      )
                    : null,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                profile.displayName,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Local Development Profile',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xhu),
              const Divider(),
              const SizedBox(height: AppSpacing.lg),
              const ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('Profile preview only'),
                subtitle: Text('Editing and settings are coming soon.'),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            const Center(child: Text('Could not load profile.')),
      ),
    );
  }
}
