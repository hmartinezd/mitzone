import 'package:flutter_test/flutter_test.dart';
import 'package:mitzone/app/router/app_entry_resolver.dart';
import 'package:mitzone/core/identity/app_identity.dart';
import 'package:mitzone/core/identity/identity_gateway.dart';
import 'package:mitzone/features/onboarding/data/onboarding_status_store.dart';
import 'package:mitzone/features/profile/data/profile_repository.dart';
import 'package:mitzone/features/profile/domain/user_profile.dart';

class FakeOnboardingStatusStore implements OnboardingStatusStore {
  bool completed = false;
  bool shouldThrow = false;

  @override
  Future<bool> isCompleted() async {
    if (shouldThrow) throw Exception('Store error');
    return completed;
  }

  @override
  Future<void> markCompleted() async => completed = true;
}

class FakeIdentityGateway implements IdentityGateway {
  AppIdentity? identity;
  bool shouldThrow = false;

  @override
  Future<AppIdentity> ensureIdentity() async {
    if (shouldThrow) throw Exception('Identity error');
    identity ??= const AppIdentity(
      id: 'test-id',
      type: AppIdentityType.localDevelopment,
    );
    return identity!;
  }

  @override
  Future<AppIdentity?> getExistingIdentity() async => identity;
}

class FakeProfileRepository implements ProfileRepository {
  UserProfile? profile;
  bool shouldThrow = false;

  @override
  Future<UserProfile?> getProfile(String identityId) async {
    if (shouldThrow) throw Exception('Repo error');
    return profile;
  }

  @override
  Future<UserProfile> saveMinimumProfile({
    required String identityId,
    required String displayName,
    String? avatarUri,
  }) async {
    profile = UserProfile(
      id: identityId,
      displayName: displayName,
      avatarUri: avatarUri,
    );
    return profile!;
  }

  @override
  Future<UserProfile> saveProfile(UserProfile p) async {
    profile = p;
    return profile!;
  }
}

void main() {
  group('AppEntryResolver', () {
    late FakeOnboardingStatusStore onboardingStore;
    late FakeIdentityGateway identityGateway;
    late FakeProfileRepository profileRepo;
    late AppEntryResolver resolver;

    setUp(() {
      onboardingStore = FakeOnboardingStatusStore();
      identityGateway = FakeIdentityGateway();
      profileRepo = FakeProfileRepository();

      resolver = AppEntryResolver(
        onboardingStatusStore: onboardingStore,
        identityGateway: identityGateway,
        profileRepository: profileRepo,
      );
    });

    test('resolves to onboarding when incomplete', () async {
      onboardingStore.completed = false;
      final target = await resolver.resolve();
      expect(target, AppEntryTarget.onboarding);
    });

    test(
      'resolves to createProfile when onboarding complete but no profile',
      () async {
        onboardingStore.completed = true;
        profileRepo.profile = null;

        final target = await resolver.resolve();
        expect(target, AppEntryTarget.createProfile);
      },
    );

    test(
      'resolves to createProfile when profile incomplete (short name)',
      () async {
        onboardingStore.completed = true;
        profileRepo.profile = const UserProfile(id: 'id', displayName: 'H');

        final target = await resolver.resolve();
        expect(target, AppEntryTarget.createProfile);
      },
    );

    test('resolves to ready when profile complete', () async {
      onboardingStore.completed = true;
      profileRepo.profile = const UserProfile(id: 'id', displayName: 'Hector');

      final target = await resolver.resolve();
      expect(target, AppEntryTarget.ready);
    });

    test(
      'safely resolves to onboarding when onboarding store throws',
      () async {
        onboardingStore.shouldThrow = true;
        final target = await resolver.resolve();
        expect(target, AppEntryTarget.onboarding);
      },
    );

    test('resolves to entryFailure when identity gateway throws', () async {
      onboardingStore.completed = true;
      identityGateway.shouldThrow = true;
      final target = await resolver.resolve();
      expect(target, AppEntryTarget.entryFailure);
    });
  });
}
