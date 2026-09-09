import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import '../config/app_environment.dart';

final appConfigProvider = Provider<AppConfig>((ref) {
  // Bootstrap overrides this with compile-time configuration. A local
  // default keeps direct app/test entry points in the documented demo mode.
  return AppConfig.validated(env: AppEnvironment.local);
});

final isSupabaseConfiguredProvider = Provider<bool>((ref) {
  final config = ref.watch(appConfigProvider);
  return config.isSupabaseConfigured;
});
