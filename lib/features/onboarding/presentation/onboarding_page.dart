import 'package:flutter/material.dart';
import '../../../app/theme/app_spacing.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({
    required this.title,
    required this.description,
    required this.illustration,
    super.key,
  });

  final String title;
  final String description;
  final Widget illustration;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: AppSpacing.xxl),
          Semantics(
            label: 'Illustration representing: $title',
            child: SizedBox(height: 250, child: illustration),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            title,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            description,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}
