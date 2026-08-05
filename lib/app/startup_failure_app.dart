import 'package:flutter/material.dart';
import 'theme/app_theme.dart';

class StartupFailureApp extends StatelessWidget {
  final String message;

  const StartupFailureApp({required this.message, super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mitzone',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.redAccent,
                    size: 64,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Could not start Mitzone',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      // In a real app, this might trigger a restart logic
                    },
                    child: const Text('Check configuration and retry'),
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
