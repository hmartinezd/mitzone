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
          _BrandMark(size: size),
          if (showText) ...[
            const SizedBox(height: AppSpacing.sm),
            // The supplied logo already contains the Mitzone wordmark. Keep
            // the text in the tree for accessibility and backwards
            // compatibility with callers that request the brand label.
            Opacity(
              opacity: 0,
              child: Text(
                'Mitzone',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
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

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.12),
      child: Image.asset(
        'assets/branding/mitzone_logo_square.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (context, error, stackTrace) =>
            _BrandMarkFallback(size: size),
      ),
    );
  }
}

class _BrandMarkFallback extends StatelessWidget {
  const _BrandMarkFallback({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: theme.colorScheme.primary, width: 2),
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.location_on_outlined,
              size: size * 0.6,
              color: theme.colorScheme.primary,
            ),
            Positioned(
              top: size * 0.25,
              child: Container(
                width: size * 0.15,
                height: size * 0.15,
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
