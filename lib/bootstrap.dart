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
import 'core/errors/app_exception.dart';
import 'core/observability/observability.dart';
import 'core/observability/observability_provider.dart';
import 'package:firebase_core/firebase_core.dart';

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

// The auth repository owns callback handling so validation and error state are
// observed before a recovery session can trigger ordinary app navigation.
Future<void> _initializeSupabase({
  required String url,
  required String publishableKey,
}) async {
  await Supabase.initialize(
    url: url,
    publishableKey: publishableKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
      detectSessionInUri: false,
    ),
  );
}

Zone? _bindingZone;

/// Bootstraps the application with injected dependencies for testability.
Future<void> bootstrap({
  AppConfigLoader configLoader = AppConfig.fromEnvironment,
  SupabaseInitializer supabaseInitializer = _initializeSupabase,
  AppRunner appRunner = runApp,
}) async {
  // A retry is invoked from the startup-failure widget's zone. Reusing that
  // zone keeps it aligned with the zone in which Flutter bindings were
  // initialized; creating a second guarded zone would trigger Flutter's
  // zone-mismatch assertion when runApp is called.
  if (_bindingZone != null && identical(_bindingZone, Zone.current)) {
    await _bootstrapInCurrentZone(
      configLoader: configLoader,
      supabaseInitializer: supabaseInitializer,
      appRunner: appRunner,
    );
    return;
  }

  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      _bindingZone = Zone.current;
      await _bootstrapInCurrentZone(
        configLoader: configLoader,
        supabaseInitializer: supabaseInitializer,
        appRunner: appRunner,
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

Future<void> _bootstrapInCurrentZone({
  required AppConfigLoader configLoader,
  required SupabaseInitializer supabaseInitializer,
  required AppRunner appRunner,
}) async {
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
    try {
      await Firebase.initializeApp();
    } catch (e) {
      if (kDebugMode) {
        developer.log(
          'Firebase unavailable: ${e.runtimeType}',
          name: 'mitzone.bootstrap',
        );
      }
    }
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
      overrides: [
        appConfigProvider.overrideWithValue(config),
        observabilityProvider.overrideWithValue(
          await initializeObservability(),
        ),
      ],
      child: const MitzoneApp(),
    ),
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
      message: _startupMessage(category: category, error: error),
      // Provide a retry mechanism that re-runs bootstrap with default dependencies.
      onRetry: () => bootstrap(),
    ),
  );
}

String _startupMessage({required String category, required Object error}) {
  if (error is ConfigException) return error.message;

  return 'The application could not start due to a $category. '
      'Please verify your environment configuration.';
}
