import 'package:flutter/material.dart';
import '../../app/theme/app_spacing.dart';

class MitzoneBrand extends StatelessWidget {
  const MitzoneBrand({
    super.key,
    this.size = 48,
    this.showText = true,
    this.showTagline = false,
    this.alignment = CrossAxisAlignment.center,
  });

  final double size;
  final bool showText;
  final bool showTagline;
  final CrossAxisAlignment alignment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: 'Mitzone Brand',
      container: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: alignment,
        children: [
          if (showText)
            Text(
              'Mitzone',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          if (showTagline) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Real world. Real connections.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
