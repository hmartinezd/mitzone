import 'package:flutter/material.dart';

/// A compact reminder of the product's consent model. Discovery and explicit
/// presence controls should remain the useful focus of a returning user's Home.
class SharedMomentsHero extends StatelessWidget {
  const SharedMomentsHero({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Real moments, voluntary digital connection.',
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'Explore nearby. Choose when to be discoverable. Connect only when you both agree.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class QuietMomentsCard extends StatelessWidget {
  const QuietMomentsCard({required this.onExplore, super.key});
  final VoidCallback onExplore;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'No shared moments yet',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 8),
      Text(
        'Discover an activity that interests you. Presence is always a separate choice.',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      const SizedBox(height: 8),
      TextButton.icon(
        onPressed: onExplore,
        icon: const Icon(Icons.explore_outlined),
        label: const Text('Browse nearby activities'),
      ),
    ],
  );
}
