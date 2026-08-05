import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_radii.dart';

enum MitzoneStatus { neutral, info, success, warning, error }

class MitzoneStatusBadge extends StatelessWidget {
  const MitzoneStatusBadge({
    required this.text,
    super.key,
    this.status = MitzoneStatus.neutral,
  });

  final String text;
  final MitzoneStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = _getColorScheme();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colorScheme.container,
        borderRadius: AppRadii.radiusPill,
        border: Border.all(
          color: colorScheme.foreground.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getIcon(), size: 14, color: colorScheme.foreground),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              text,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.foreground,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIcon() {
    switch (status) {
      case MitzoneStatus.neutral:
        return Icons.info_outline;
      case MitzoneStatus.info:
        return Icons.info;
      case MitzoneStatus.success:
        return Icons.check_circle;
      case MitzoneStatus.warning:
        return Icons.warning;
      case MitzoneStatus.error:
        return Icons.error;
    }
  }

  _BadgeColors _getColorScheme() {
    switch (status) {
      case MitzoneStatus.neutral:
        return _BadgeColors(
          container: AppColors.surfaceElevated,
          foreground: AppColors.textSecondary,
        );
      case MitzoneStatus.info:
        return _BadgeColors(
          container: AppColors.infoContainer,
          foreground: AppColors.info,
        );
      case MitzoneStatus.success:
        return _BadgeColors(
          container: AppColors.successContainer,
          foreground: AppColors.success,
        );
      case MitzoneStatus.warning:
        return _BadgeColors(
          container: AppColors.warningContainer,
          foreground: AppColors.warning,
        );
      case MitzoneStatus.error:
        return _BadgeColors(
          container: AppColors.errorContainer,
          foreground: AppColors.error,
        );
    }
  }
}

class _BadgeColors {
  _BadgeColors({required this.container, required this.foreground});
  final Color container;
  final Color foreground;
}
