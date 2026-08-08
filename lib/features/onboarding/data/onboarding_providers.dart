import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'onboarding_status_store.dart';
import 'shared_preferences_onboarding_status_store.dart';

/// Provider for [SharedPreferencesAsync].
final sharedPreferencesAsyncProvider = Provider<SharedPreferencesAsync>((ref) {
  return SharedPreferencesAsync();
});

/// Provider for [OnboardingStatusStore].
final onboardingStatusStoreProvider = Provider<OnboardingStatusStore>((ref) {
  final prefs = ref.watch(sharedPreferencesAsyncProvider);
  return SharedPreferencesOnboardingStatusStore(prefs);
});
