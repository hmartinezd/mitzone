import 'package:flutter_test/flutter_test.dart';
import 'package:mitzone/app/router/app_entry_resolver.dart';
import 'package:mitzone/features/onboarding/data/onboarding_status_store.dart';

class FakeOnboardingStatusStore implements OnboardingStatusStore {
  bool completed = false;
  bool shouldThrow = false;

  @override
  Future<bool> isCompleted() async {
    if (shouldThrow) throw Exception('Storage error');
    return completed;
  }

  @override
  Future<void> markCompleted() async {
    if (shouldThrow) throw Exception('Storage error');
    completed = true;
  }
}

void main() {
  group('AppEntryResolver', () {
    late FakeOnboardingStatusStore store;
    late AppEntryResolver resolver;

    setUp(() {
      store = FakeOnboardingStatusStore();
      resolver = AppEntryResolver(store);
    });

    test('resolves to onboarding when store reports incomplete', () async {
      store.completed = false;
      final target = await resolver.resolve();
      expect(target, AppEntryTarget.onboarding);
    });

    test('resolves to postOnboarding when store reports complete', () async {
      store.completed = true;
      final target = await resolver.resolve();
      expect(target, AppEntryTarget.postOnboarding);
    });

    test('safely resolves to onboarding when store throws', () async {
      store.shouldThrow = true;
      final target = await resolver.resolve();
      expect(target, AppEntryTarget.onboarding);
    });
  });
}
