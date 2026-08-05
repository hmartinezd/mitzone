import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
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
    return Semantics(
      label: 'Mitzone Brand',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: alignment,
        children: [
          _BrandMark(size: size),
          if (showText) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Mitzone',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
          if (showTagline) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Real world. Real connections.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
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
    // Temporary brand mark: A stylized "M" combined with a connection point motif
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary, width: 2),
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.location_on_outlined,
              size: size * 0.6,
              color: AppColors.primary,
            ),
            Positioned(
              top: size * 0.25,
              child: Container(
                width: size * 0.15,
                height: size * 0.15,
                decoration: const BoxDecoration(
                  color: AppColors.secondary,
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
