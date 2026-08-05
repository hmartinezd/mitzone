import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router/app_routes.dart';

class RouteErrorScreen extends StatelessWidget {
  /// The [error] is kept for debug logging if needed, but not displayed to the user.
  final Exception? error;

  const RouteErrorScreen({super.key, this.error});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 48.0,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.explore_outlined,
                    size: 80,
                    color: theme.colorScheme.primary,
                    semanticLabel:
                        'Lost explorer icon representing page not found',
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Page Not Found',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "We couldn't find the page you're looking for. "
                    "It might have been moved or doesn't exist.",
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 48),
                  FilledButton(
                    onPressed: () => context.go(AppRoutes.foundation),
                    child: const Text('Return to Mitzone'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
