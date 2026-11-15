import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/app_routes.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({required this.displayName, super.key});
  final String? displayName;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      IconButton(
        tooltip: 'Profile',
        onPressed: () => context.go(AppRoutes.profile),
        icon: const Icon(Icons.account_circle_outlined),
        style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
      Expanded(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Mitzone',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            Text(
              displayName == null ? 'Welcome back' : 'Hi, $displayName',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      IconButton(
        tooltip: 'Messages',
        onPressed: () => context.push(AppRoutes.chat),
        icon: const Icon(Icons.chat_bubble_outline_rounded),
        style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
    ],
  );
}
