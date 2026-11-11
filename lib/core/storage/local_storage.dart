/// Interface for basic key-value local storage.
abstract interface class LocalStorage {
  /// Retrieves a string value for the given [key].
  Future<String?> getString(String key);

  /// Persists a string [value] for the given [key].
  Future<void> setString(String key, String value);

  /// Retrieves a boolean value for the given [key].
  Future<bool?> getBool(String key);

  /// Persists a boolean [value] for the given [key].
  Future<void> setBool(String key, bool value);
}
