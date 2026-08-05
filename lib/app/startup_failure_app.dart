import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import '../features/foundation/presentation/startup_failure_screen.dart';

class StartupFailureApp extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const StartupFailureApp({required this.message, this.onRetry, super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mitzone',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      home: StartupFailureScreen(message: message, onRetry: onRetry),
    );
  }
}
