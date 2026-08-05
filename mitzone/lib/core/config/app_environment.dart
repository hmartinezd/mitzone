enum AppEnvironment {
  local,
  development,
  staging,
  production;

  static AppEnvironment fromString(String? value) {
    return AppEnvironment.values.firstWhere(
      (e) => e.name == value?.toLowerCase(),
      orElse: () => AppEnvironment.local,
    );
  }
}
