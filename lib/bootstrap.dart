import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app/app.dart';
import 'app/startup_failure_app.dart';
import 'core/config/app_config.dart';
import 'core/providers/core_providers.dart';

/// Typedef for Supabase initialization to allow mocking in tests.
typedef SupabaseInitializer =
    Future<void> Function({
      required String url,
      required String publishableKey,
    });

Future<void> bootstrap({
  SupabaseInitializer supabaseInitializer = Supabase.initialize,
}) async {
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      final AppConfig config;
      try {
        config = AppConfig.fromEnvironment();
      } catch (e, stack) {
        _handleStartupError('Configuration failure', e, stack);
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
        _handleStartupError('Initialization failure', e, stack);
        return;
      }

      runApp(
        ProviderScope(
          overrides: [appConfigProvider.overrideWithValue(config)],
          child: const MitzoneApp(),
        ),
      );
    },
    (error, stack) {
      _handleStartupError('Unexpected failure', error, stack);
    },
  );
}

void _handleStartupError(String type, Object error, StackTrace stack) {
  developer.log(
    'Startup error: $type',
    error: error,
    stackTrace: stack,
    name: 'mitzone.bootstrap',
  );

  runApp(
    StartupFailureApp(
      message:
          'The application could not start due to a $type. '
          'Please verify your environment configuration.',
    ),
  );
}
