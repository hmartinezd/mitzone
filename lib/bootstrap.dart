import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app/app.dart';
import 'app/startup_failure_app.dart';
import 'core/config/app_config.dart';
import 'core/providers/core_providers.dart';

/// Typedef for loading application configuration.
typedef AppConfigLoader = AppConfig Function();

/// Typedef for initializing external services like Supabase.
typedef SupabaseInitializer =
    Future<void> Function({
      required String url,
      required String publishableKey,
    });

/// Typedef for running the application widget tree.
typedef AppRunner = void Function(Widget app);

/// Bootstraps the application with injected dependencies for testability.
Future<void> bootstrap({
  AppConfigLoader configLoader = AppConfig.fromEnvironment,
  SupabaseInitializer supabaseInitializer = Supabase.initialize,
  AppRunner appRunner = runApp,
}) async {
  // Ensure Flutter bindings are initialized before any plugin usage.
  WidgetsFlutterBinding.ensureInitialized();

  await runZonedGuarded(
    () async {
      final AppConfig config;
      try {
        config = configLoader();
      } catch (e, stack) {
        _handleStartupError(
          category: 'Configuration failure',
          error: e,
          stackTrace: stack,
          appRunner: appRunner,
        );
        return;
      }

      try {
        if (config.isSupabaseConfigured) {
          await supabaseInitializer(
            url: config.supabaseUrl!,
            publishableKey: config.supabasePublishableKey!,
          );
        }
      } catch (e, stack) {
        _handleStartupError(
          category: 'Initialization failure',
          error: e,
          stackTrace: stack,
          appRunner: appRunner,
        );
        return;
      }

      appRunner(
        ProviderScope(
          overrides: [appConfigProvider.overrideWithValue(config)],
          child: const MitzoneApp(),
        ),
      );
    },
    (error, stack) {
      _handleStartupError(
        category: 'Unexpected failure',
        error: error,
        stackTrace: stack,
        appRunner: appRunner,
      );
    },
  );
}

/// Handles and logs startup errors while showing a failure UI.
void _handleStartupError({
  required String category,
  required Object error,
  required StackTrace stackTrace,
  required AppRunner appRunner,
}) {
  if (kDebugMode) {
    developer.log(
      'Startup failure: $category (${error.runtimeType})',
      stackTrace: stackTrace,
      name: 'mitzone.bootstrap',
    );
  }

  appRunner(
    StartupFailureApp(
      message:
          'The application could not start due to a $category. '
          'Please verify your environment configuration.',
      // Provide a retry mechanism that re-runs bootstrap with default dependencies.
      onRetry: () => bootstrap(),
    ),
  );
}
