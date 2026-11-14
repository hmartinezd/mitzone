import 'package:flutter/material.dart';

import '../../../../app/theme/kinetic_colors.dart';
import '../../../../shared/widgets/mitzone_card.dart';

/// Static shared-context metaphor from the approved Stitch Home.
/// It does not render users, movement, live coordinates or presence evidence.
class SharedMomentsHero extends StatelessWidget {
  const SharedMomentsHero({super.key});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MitzoneCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _badge(context, 'Your choice', Icons.lock_outline),
              _badge(context, 'Shared experiences', Icons.interests_outlined),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Real moments, voluntary digital connection.',
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Discover places and activities. Choose when to be discoverable, and connect only when you both agree.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                ExcludeSemantics(
                  child: MediaQuery.withNoTextScaling(
                    child: SizedBox(
                      width: 224,
                      height: 144,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned(
                            left: 12,
                            child: _circle(
                              KineticColors.cyan,
                              'Places',
                              Icons.storefront_outlined,
                            ),
                          ),
                          Positioned(
                            right: 12,
                            child: _circle(
                              KineticColors.teal,
                              'Activities',
                              Icons.local_activity_outlined,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(99),
                              border: Border.all(color: KineticColors.cyan),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.favorite_border,
                                  size: 16,
                                  color: KineticColors.primary,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'You',
                                  style: TextStyle(
                                    color: KineticColors.ink,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Places + Activities + You',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(BuildContext context, String label, IconData icon) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.secondaryContainer,
      borderRadius: BorderRadius.circular(99),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: Theme.of(context).colorScheme.onSecondaryContainer,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
          ),
        ),
      ],
    ),
  );
  Widget _circle(Color color, String title, IconData icon) => Container(
    width: 112,
    height: 112,
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white70, width: 2),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          color: color == KineticColors.cyan
              ? KineticColors.primary
              : Colors.white,
          size: 22,
        ),
        Text(
          title,
          style: TextStyle(
            color: color == KineticColors.cyan
                ? KineticColors.primary
                : Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class QuietMomentsCard extends StatelessWidget {
  const QuietMomentsCard({required this.onExplore, super.key});
  final VoidCallback onExplore;
  @override
  Widget build(BuildContext context) => MitzoneCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'No shared moments yet',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'A quiet start is welcome. Discover an activity that interests you. Presence is always a separate choice.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: onExplore,
          icon: const Icon(Icons.explore_outlined),
          label: const Text('Browse nearby activities'),
        ),
      ],
    ),
  );
}
