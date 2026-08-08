import 'package:flutter/material.dart';
import '../../app/theme/app_gradients.dart';
import '../../app/theme/app_spacing.dart';

/// A reusable component for page content that includes the Mitzone background,
/// SafeArea, padding, and optional scrolling/centering.
///
/// This is intended to be used either inside a [Scaffold] (via [MitzonePageScaffold])
/// or directly as a branch in a [MainNavigationShell].
class MitzonePageBody extends StatelessWidget {
  const MitzonePageBody({
    required this.child,
    super.key,
    this.title,
    this.useSafeArea = true,
    this.scrollable = true,
    this.horizontalPadding = AppSpacing.mobilePagePadding,
    this.centered = false,
    this.onBack,
  });

  final Widget child;
  final String? title;
  final bool useSafeArea;
  final bool scrollable;
  final double horizontalPadding;
  final bool centered;

  /// Optional callback to show a visual Back affordance.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget content = child;

    // If a title or back button is provided, we render it at the top.
    if (title != null || onBack != null) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (onBack != null) ...[
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: onBack,
                  tooltip: 'Back',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minHeight: 48,
                    minWidth: 48,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              if (title != null)
                Expanded(
                  child: Text(
                    title!,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      );
    }

    if (centered) {
      content = Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppSpacing.maxContentWidthCompact,
          ),
          child: content,
        ),
      );
    }

    if (scrollable) {
      content = SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: content,
      );
    } else {
      content = Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: content,
      );
    }

    if (useSafeArea) {
      content = SafeArea(child: content);
    }

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppGradients.backgroundAtmospheric,
      ),
      child: content,
    );
  }
}
