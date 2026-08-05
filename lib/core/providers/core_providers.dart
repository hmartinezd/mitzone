import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';

final appConfigProvider = Provider<AppConfig>((ref) {
  throw UnimplementedError(
    'appConfigProvider must be overridden in ProviderScope',
  );
});

final isSupabaseConfiguredProvider = Provider<bool>((ref) {
  final config = ref.watch(appConfigProvider);
  return config.isSupabaseConfigured;
});
