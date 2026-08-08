import 'package:flutter/material.dart';
import '../../../../shared/widgets/mitzone_card.dart';
import '../../../../shared/widgets/mitzone_button.dart';
import '../../../../app/theme/app_spacing.dart';

class HomeProfileCard extends StatelessWidget {
  const HomeProfileCard({required this.onViewProfile, super.key});

  final VoidCallback onViewProfile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MitzoneCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.badge_outlined, color: theme.colorScheme.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Complete your profile',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Soon you will be able to add interests, languages, and bio to help others get to know you better.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          MitzoneButton(
            text: 'View profile',
            onPressed: onViewProfile,
            variant: MitzoneButtonVariant.secondary,
            fullWidth: false,
          ),
        ],
      ),
    );
  }
}
