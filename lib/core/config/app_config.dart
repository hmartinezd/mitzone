import '../errors/app_exception.dart';
import 'app_environment.dart';

class AppConfig {
  final AppEnvironment env;
  final String? supabaseUrl;
  final String? supabasePublishableKey;

  const AppConfig({
    required this.env,
    this.supabaseUrl,
    this.supabasePublishableKey,
  });

  /// Factory that performs validation.
  factory AppConfig.validated({
    required AppEnvironment env,
    String? supabaseUrl,
    String? supabasePublishableKey,
  }) {
    final config = AppConfig(
      env: env,
      supabaseUrl: supabaseUrl?.trim().isEmpty ?? true
          ? null
          : supabaseUrl?.trim(),
      supabasePublishableKey: supabasePublishableKey?.trim().isEmpty ?? true
          ? null
          : supabasePublishableKey?.trim(),
    );
    config._validate();
    return config;
  }

  factory AppConfig.fromEnvironment() {
    const envStr = String.fromEnvironment('APP_ENV', defaultValue: 'local');
    const urlStr = String.fromEnvironment('SUPABASE_URL');
    const keyStr = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

    return AppConfig.validated(
      env: AppEnvironment.fromString(envStr),
      supabaseUrl: urlStr,
      supabasePublishableKey: keyStr,
    );
  }

  void _validate() {
    final hasUrl = supabaseUrl != null;
    final hasKey = supabasePublishableKey != null;

    if (hasUrl != hasKey) {
      throw const ConfigException(
        'Partial Supabase configuration detected. '
        'Both SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY must be provided or both must be absent.',
      );
    }

    if (hasUrl) {
      final uri = Uri.tryParse(supabaseUrl!);
      final isValid =
          uri != null &&
          uri.isAbsolute &&
          ['http', 'https'].contains(uri.scheme) &&
          uri.host.isNotEmpty;

      if (!isValid) {
        throw const ConfigException(
          'Invalid SUPABASE_URL. It must be a valid absolute HTTP or HTTPS URI.',
        );
      }
    }
  }

  bool get isSupabaseConfigured =>
      supabaseUrl != null && supabasePublishableKey != null;

  @override
  String toString() {
    return 'AppConfig(environment: ${env.name}, supabaseConfigured: $isSupabaseConfigured)';
  }

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
