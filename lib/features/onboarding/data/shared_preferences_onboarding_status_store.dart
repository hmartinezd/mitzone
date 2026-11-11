import '../../../core/storage/local_storage.dart';
import 'onboarding_status_store.dart';

/// Implementation of [OnboardingStatusStore] using [LocalStorage].
class SharedPreferencesOnboardingStatusStore implements OnboardingStatusStore {
  const SharedPreferencesOnboardingStatusStore(this._storage);

  final LocalStorage _storage;

  static const String _onboardingCompletedKey = 'onboarding.completed.v1';

  @override
  Future<bool> isCompleted() async {
    return await _storage.getBool(_onboardingCompletedKey) ?? false;
  }

  @override
  Future<void> markCompleted() async {
    await _storage.setBool(_onboardingCompletedKey, true);
  }
}
