import 'package:shared_preferences/shared_preferences.dart';
import 'onboarding_status_store.dart';

/// Implementation of [OnboardingStatusStore] using [SharedPreferencesAsync].
class SharedPreferencesOnboardingStatusStore implements OnboardingStatusStore {
  const SharedPreferencesOnboardingStatusStore(this._prefs);

  final SharedPreferencesAsync _prefs;

  static const String _onboardingCompletedKey = 'onboarding.completed.v1';

  @override
  Future<bool> isCompleted() async {
    return await _prefs.getBool(_onboardingCompletedKey) ?? false;
  }

  @override
  Future<void> markCompleted() async {
    await _prefs.setBool(_onboardingCompletedKey, true);
  }
}
