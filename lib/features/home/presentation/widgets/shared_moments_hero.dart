import 'package:flutter/material.dart';

/// Editorial introduction. No people, attendance or location state is invented.
class SharedMomentsHero extends StatelessWidget {
  const SharedMomentsHero({super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Real moments, intentional connection.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'Your presence. Your choice.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ),
  );
}

class QuietMomentsCard extends StatelessWidget {
  const QuietMomentsCard({required this.onExplore, super.key});
  final VoidCallback onExplore;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'No shared moments yet',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 6),
        Text(
          'Start with a place or activity you love.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: onExplore,
          icon: const Icon(Icons.explore_outlined),
          label: const Text('Browse nearby activities'),
        ),
      ],
    ),
  );
}
