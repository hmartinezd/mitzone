import 'package:flutter/material.dart';
import '../../app/theme/app_spacing.dart';

class MitzoneLoadingIndicator extends StatelessWidget {
  const MitzoneLoadingIndicator({super.key, this.text, this.compact = false});

  final String? text;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final indicator = Semantics(
      label: 'Loading',
      child: const CircularProgressIndicator(),
    );

    if (compact) {
      return SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: theme.colorScheme.primary,
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        indicator,
        if (text != null) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(
            text!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
