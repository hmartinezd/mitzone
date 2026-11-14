import 'package:flutter/material.dart';

import '../../app/theme/app_spacing.dart';

class MitzoneEmptyState extends StatelessWidget {
  const MitzoneEmptyState({
    required this.title,
    required this.message,
    super.key,
    this.icon,
    this.primaryAction,
    this.secondaryAction,
  });

  final String title;
  final String message;
  final IconData? icon;
  final Widget? primaryAction;
  final Widget? secondaryAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppSpacing.maxContentWidthCompact,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 40, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(height: AppSpacing.md),
              ],
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              if (primaryAction != null || secondaryAction != null) ...[
                const SizedBox(height: AppSpacing.lg),
                if (primaryAction != null) ...[primaryAction!],
                if (secondaryAction != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  secondaryAction!,
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
