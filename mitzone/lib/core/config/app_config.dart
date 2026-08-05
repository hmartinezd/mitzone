import 'app_environment.dart';

class AppConfig {
  final AppEnvironment env;
  final String? supabaseUrl;
  final String? supabasePublishableKey;

  const AppConfig({
    required this.env,
    this.supabaseUrl,
    this.supabasePublishableKey,
  }) : assert(
         (supabaseUrl == null && supabasePublishableKey == null) ||
             (supabaseUrl != null && supabasePublishableKey != null),
         'Both supabaseUrl and supabasePublishableKey must be provided or both must be null',
       );

  factory AppConfig.fromEnvironment() {
    const env = String.fromEnvironment('APP_ENV', defaultValue: 'local');
    const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
    const supabaseKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

    return AppConfig(
      env: AppEnvironment.fromString(env),
      supabaseUrl: supabaseUrl.isEmpty ? null : supabaseUrl,
      supabasePublishableKey: supabaseKey.isEmpty ? null : supabaseKey,
    );
  }

  bool get isSupabaseConfigured =>
      supabaseUrl != null && supabasePublishableKey != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppConfig &&
          runtimeType == other.runtimeType &&
          env == other.env &&
          supabaseUrl == other.supabaseUrl &&
          supabasePublishableKey == other.supabasePublishableKey;

  @override
  int get hashCode =>
      env.hashCode ^ supabaseUrl.hashCode ^ supabasePublishableKey.hashCode;
}
