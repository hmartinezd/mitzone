import 'package:flutter/material.dart';
import '../../../../shared/widgets/mitzone_card.dart';
import '../../../../shared/widgets/mitzone_button.dart';
import '../../../../app/theme/app_spacing.dart';

class HomeMatchesCard extends StatelessWidget {
  const HomeMatchesCard({
    required this.onExploreEvents,
    required this.onScanQR,
    super.key,
  });

  final VoidCallback onExploreEvents;
  final VoidCallback onScanQR;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Matches',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        MitzoneCard(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            children: [
              Icon(
                Icons.people_outline,
                size: 48,
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.5,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'No matches yet',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Join an event or scan a QR code to start discovering people.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: MitzoneButton(
                      text: 'Explore events',
                      onPressed: onExploreEvents,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        MitzoneButton(
                          text: 'Scan QR',
                          onPressed: onScanQR,
                          variant: MitzoneButtonVariant.secondary,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Coming soon',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
