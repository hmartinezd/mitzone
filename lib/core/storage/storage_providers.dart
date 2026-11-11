import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'local_storage.dart';
import 'shared_preferences_local_storage.dart';

/// Provider for [SharedPreferencesAsync].
final sharedPreferencesAsyncProvider = Provider<SharedPreferencesAsync>((ref) {
  return SharedPreferencesAsync();
});

/// Provider for the [LocalStorage] abstraction.
final localStorageProvider = Provider<LocalStorage>((ref) {
  final prefs = ref.watch(sharedPreferencesAsyncProvider);
  return SharedPreferencesLocalStorage(prefs);
});
