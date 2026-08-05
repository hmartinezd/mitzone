import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_radii.dart';

class MitzoneCard extends StatelessWidget {
  const MitzoneCard({
    required this.child,
    super.key,
    this.padding,
    this.onTap,
    this.leading,
    this.emphasized = false,
    this.selected = false,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Widget? leading;
  final bool emphasized;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final isTappable = onTap != null;

    Widget content = Padding(
      padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: AppSpacing.md),
          ],
          Expanded(child: child),
        ],
      ),
    );

    if (isTappable) {
      content = InkWell(
        onTap: onTap,
        borderRadius: AppRadii.radiusLg,
        child: content,
      );
    }

    return Semantics(
      selected: selected,
      enabled: true,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.radiusLg,
          side: (emphasized || selected)
              ? BorderSide(
                  color: selected ? AppColors.primary : AppColors.outlineStrong,
                  width: selected ? 2 : 1,
                )
              : BorderSide.none,
        ),
        child: content,
      ),
    );
  }
}
