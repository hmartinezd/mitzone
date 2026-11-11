import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';

/// Application configuration is supplied by [bootstrap].
///
/// Tests and other explicitly controlled entry points must override this
/// provider with the configuration they intend to exercise. There is no
/// production fallback because an absent configuration must not activate the
/// local/demo identity.
final appConfigProvider = Provider<AppConfig>((ref) {
  throw StateError(
    'Application configuration was not provided. '
    'Run the app through bootstrap() or override appConfigProvider in tests.',
  );
});

final isSupabaseConfiguredProvider = Provider<bool>((ref) {
  final config = ref.watch(appConfigProvider);
  return config.isSupabaseConfigured;
});
