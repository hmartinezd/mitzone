enum AppEnvironment {
  local,
  development,
  staging,
  production;

  static AppEnvironment fromString(String? value) {
    final normalized = value?.trim().toLowerCase();
    return AppEnvironment.values.firstWhere(
      (e) => e.name == normalized,
      orElse: () => AppEnvironment.local,
    );
  }
}
