import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router/app_routes.dart';

class RouteErrorScreen extends StatelessWidget {
  final Exception? error;

  const RouteErrorScreen({super.key, this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 48.0,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.explore_outlined,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                    semanticLabel: 'Page not found icon',
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Page Not Found',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "We couldn't find the page you're looking for. "
                    "It might have been moved or doesn't exist.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 48),
                  ElevatedButton(
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
