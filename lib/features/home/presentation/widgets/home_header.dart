import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../shared/widgets/mitzone_brand.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({required this.displayName, super.key});
  final String? displayName;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const MitzoneBrand(size: 36, showText: false),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Mitzone',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w700,
                letterSpacing: -.5,
                height: 1.1,
              ),
            ),
            Text(
              displayName == null ? 'Welcome back' : 'Hi, $displayName',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
      IconButton(
        tooltip: 'Messages',
        onPressed: () => context.push(AppRoutes.chat),
        icon: const Icon(Icons.chat_bubble_outline_rounded),
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
          foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
        ),
      ),
    ],
  );
}
