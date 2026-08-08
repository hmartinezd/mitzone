import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/identity/identity_providers.dart';
import '../../../shared/widgets/mitzone_page_body.dart';
import '../../../app/theme/app_spacing.dart';
import '../data/profile_providers.dart';

class ProfilePreviewScreen extends ConsumerWidget {
  const ProfilePreviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final identityAsync = ref.watch(identityGatewayProvider).ensureIdentity();

    return MitzonePageBody(
      title: 'Profile',
      child: FutureBuilder(
        future: identityAsync,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('Could not load profile.'));
          }

          final identity = snapshot.data!;
          final profileAsync = ref
              .watch(profileRepositoryProvider)
              .getProfile(identity.id);

          return FutureBuilder(
            future: profileAsync,
            builder: (context, profileSnapshot) {
              if (profileSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (profileSnapshot.hasError || !profileSnapshot.hasData) {
                return const Center(child: Text('Profile not found.'));
              }

              final profile = profileSnapshot.data!;

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
          );
        },
      ),
    );
  }
}
