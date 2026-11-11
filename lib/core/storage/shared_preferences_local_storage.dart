import 'package:shared_preferences/shared_preferences.dart';
import 'local_storage.dart';

/// Implementation of [LocalStorage] using [SharedPreferencesAsync].
class SharedPreferencesLocalStorage implements LocalStorage {
  const SharedPreferencesLocalStorage(this._prefs);

  final SharedPreferencesAsync _prefs;

  @override
  Future<String?> getString(String key) => _prefs.getString(key);

  @override
  Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);

  @override
  Future<bool?> getBool(String key) => _prefs.getBool(key);

  @override
  Future<void> setBool(String key, bool value) => _prefs.setBool(key, value);
}
