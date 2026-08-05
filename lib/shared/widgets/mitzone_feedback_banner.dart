import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_radii.dart';

enum MitzoneFeedbackType { info, success, warning, error }

class MitzoneFeedbackBanner extends StatelessWidget {
  const MitzoneFeedbackBanner({
    required this.title,
    super.key,
    this.message,
    this.type = MitzoneFeedbackType.info,
    this.action,
    this.onDismiss,
  });

  final String title;
  final String? message;
  final MitzoneFeedbackType type;
  final Widget? action;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = _getColorScheme();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.container,
        borderRadius: AppRadii.radiusLg,
        border: Border.all(
          color: colorScheme.foreground.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(_getIcon(), color: colorScheme.foreground),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.foreground,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (message != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        message!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.foreground.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onDismiss != null)
                IconButton(
                  icon: Icon(
                    Icons.close,
                    size: 20,
                    color: colorScheme.foreground,
                  ),
                  onPressed: onDismiss,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          if (action != null) ...[
            const SizedBox(height: AppSpacing.md),
            action!,
          ],
        ],
      ),
    );
  }

  IconData _getIcon() {
    switch (type) {
      case MitzoneFeedbackType.info:
        return Icons.info;
      case MitzoneFeedbackType.success:
        return Icons.check_circle;
      case MitzoneFeedbackType.warning:
        return Icons.warning;
      case MitzoneFeedbackType.error:
        return Icons.error_outline;
    }
  }

  _BannerColors _getColorScheme() {
    switch (type) {
      case MitzoneFeedbackType.info:
        return _BannerColors(
          container: AppColors.infoContainer,
          foreground: AppColors.info,
        );
      case MitzoneFeedbackType.success:
        return _BannerColors(
          container: AppColors.successContainer,
          foreground: AppColors.success,
        );
      case MitzoneFeedbackType.warning:
        return _BannerColors(
          container: AppColors.warningContainer,
          foreground: AppColors.warning,
        );
      case MitzoneFeedbackType.error:
        return _BannerColors(
          container: AppColors.errorContainer,
          foreground: AppColors.error,
        );
    }
  }
}

class _BannerColors {
  _BannerColors({required this.container, required this.foreground});
  final Color container;
  final Color foreground;
}
