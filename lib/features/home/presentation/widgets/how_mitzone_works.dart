import 'package:flutter/material.dart';
import '../../../../app/theme/app_spacing.dart';

class HowMitzoneWorks extends StatelessWidget {
  const HowMitzoneWorks({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How Mitzone works',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _buildStep(
          context,
          icon: Icons.celebration_outlined,
          title: '1. Share a real moment',
          description:
              'Attend an event or be part of the same real-world experience.',
        ),
        const SizedBox(height: AppSpacing.lg),
        _buildStep(
          context,
          icon: Icons.search_outlined,
          title: '2. Discover later',
          description:
              'Mitzone helps people who shared that experience find one another.',
        ),
        const SizedBox(height: AppSpacing.lg),
        _buildStep(
          context,
          icon: Icons.favorite_border,
          title: '3. Connect voluntarily',
          description:
              'Both people stay in control of whether a connection continues.',
        ),
      ],
    );
  }

  Widget _buildStep(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
