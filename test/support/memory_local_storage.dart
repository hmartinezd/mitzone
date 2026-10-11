import 'package:mitzone/core/storage/local_storage.dart';

/// Isolates widget fixtures from platform storage and persisted app state.
class MemoryLocalStorage implements LocalStorage {
  final Map<String, Object> _values = {};

  @override
  Future<String?> getString(String key) async => _values[key] as String?;
  @override
  Future<bool?> getBool(String key) async => _values[key] as bool?;
  @override
  Future<void> setString(String key, String value) async =>
      _values[key] = value;
  @override
  Future<void> setBool(String key, bool value) async => _values[key] = value;
}
