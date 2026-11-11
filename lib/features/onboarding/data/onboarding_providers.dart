import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/storage_providers.dart';
import 'onboarding_status_store.dart';
import 'shared_preferences_onboarding_status_store.dart';

/// Provider for [OnboardingStatusStore].
final onboardingStatusStoreProvider = Provider<OnboardingStatusStore>((ref) {
  final storage = ref.watch(localStorageProvider);
  return SharedPreferencesOnboardingStatusStore(storage);
});
