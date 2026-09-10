import '../errors/app_exception.dart';

enum AppEnvironment {
  /// Explicitly test-only/local compatibility mode.
  local,
  development,
  staging,
  production;

  static AppEnvironment fromString(String? value, {bool allowLocal = false}) {
    final normalized = value?.trim().toLowerCase();
    for (final environment in AppEnvironment.values) {
      if (environment.name == normalized &&
          (environment != AppEnvironment.local || allowLocal)) {
        return environment;
      }
    }

    if (normalized == null || normalized.isEmpty) {
      throw const ConfigException(
        'APP_ENV is required. Set it to development, staging, or production '
        'in config/dev.json.',
      );
    }

    throw ConfigException(
      'Unknown APP_ENV "$normalized". Supported values are development, '
      'staging, and production.',
    );
  }
}
