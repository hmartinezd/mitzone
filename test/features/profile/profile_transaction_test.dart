import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitzone/app/router/app_routes.dart';
import 'package:mitzone/core/identity/app_identity.dart';
import 'package:mitzone/core/identity/identity_gateway.dart';
import 'package:mitzone/core/identity/identity_providers.dart';
import 'package:mitzone/features/onboarding/data/onboarding_providers.dart';
import 'package:mitzone/features/onboarding/data/onboarding_status_store.dart';
import 'package:mitzone/features/profile/data/avatar_picker.dart';
import 'package:mitzone/features/profile/data/avatar_storage.dart';
import 'package:mitzone/features/profile/data/profile_providers.dart';
import 'package:mitzone/features/profile/data/profile_repository.dart';
import 'package:mitzone/features/profile/domain/user_profile.dart';
import 'package:mitzone/features/profile/presentation/edit_profile_screen.dart';
import 'package:mitzone/features/profile/presentation/profile_details_screen.dart';
import 'package:mitzone/app/router/app_router.dart';

class MockOnboardingStore implements OnboardingStatusStore {
  @override
  Future<bool> isCompleted() async => true;
  @override
  Future<void> markCompleted() async {}
}

class MockIdentityGateway implements IdentityGateway {
  @override
  Future<AppIdentity> ensureIdentity() async =>
      const AppIdentity(id: 'test-id', type: AppIdentityType.localDevelopment);
  @override
  Future<AppIdentity?> getExistingIdentity() async => null;
}

class MockProfileRepository implements ProfileRepository {
  UserProfile? profile = const UserProfile(
    id: 'test-id',
    displayName: 'Hector',
    avatarUri: 'original/path.png',
  );
  int saveCount = 0;
  bool shouldFail = false;
  Duration saveDelay = Duration.zero;

  @override
  Future<UserProfile?> getProfile(String identityId) async => profile;

  @override
  Future<UserProfile> saveMinimumProfile({
    required String identityId,
    required String displayName,
    String? avatarUri,
  }) async => throw UnimplementedError();

  @override
  Future<UserProfile> saveProfile(UserProfile p) async {
    saveCount++;
    if (saveDelay > Duration.zero) {
      await Future.delayed(saveDelay);
    }
    if (shouldFail) throw Exception('Save failed');
    profile = p;
    return p;
  }
}

class MockAvatarPicker implements AvatarPicker {
  PickedAvatar? result;
  bool shouldThrow = false;
  @override
  Future<PickedAvatar?> pickFromGallery() async {
    if (shouldThrow) throw Exception('Picker failed');
    return result;
  }
}

class MockAvatarStorage implements AvatarStorage {
  int saveCount = 0;
  int deleteCount = 0;
  bool shouldSaveFail = false;
  List<String> deletedPaths = [];

  @override
  Future<String> saveAvatar({
    required String identityId,
    required String sourcePath,
  }) async {
    saveCount++;
    if (shouldSaveFail) throw Exception('Storage save failed');
    return 'managed/path/to/avatar_$saveCount.png';
  }

  @override
  Future<void> deleteAvatar({
    required String identityId,
    required String avatarPath,
  }) async {
    deleteCount++;
    deletedPaths.add(avatarPath);
  }
}

void main() {
  late MockOnboardingStore onboardingStore;
  late MockIdentityGateway identityGateway;
  late MockProfileRepository profileRepo;
  late MockAvatarPicker avatarPicker;
  late MockAvatarStorage avatarStorage;

  setUp(() {
    onboardingStore = MockOnboardingStore();
    identityGateway = MockIdentityGateway();
    profileRepo = MockProfileRepository();
    avatarPicker = MockAvatarPicker();
    avatarStorage = MockAvatarStorage();
  });

  Widget createTestWidget({String? initialLocation}) {
    return ProviderScope(
      overrides: [
        onboardingStatusStoreProvider.overrideWithValue(onboardingStore),
        identityGatewayProvider.overrideWithValue(identityGateway),
        profileRepositoryProvider.overrideWithValue(profileRepo),
        avatarPickerProvider.overrideWithValue(avatarPicker),
        avatarStorageProvider.overrideWithValue(avatarStorage),
        if (initialLocation != null)
          routerInitialLocationProvider.overrideWithValue(initialLocation),
      ],
      child: Consumer(
        builder: (context, ref, _) {
          final router = ref.watch(routerProvider);
          return MaterialApp.router(routerConfig: router);
        },
      ),
    );
  }

  group('Avatar Transactions', () {
    testWidgets('Cancel: picker returns null -> no save, no profile mutation', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(initialLocation: AppRoutes.profileEdit),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(InkWell).first); // Edit button
      await tester.pumpAndSettle();

      expect(avatarStorage.saveCount, 0);
      expect(profileRepo.saveCount, 0);
    });

    testWidgets(
      'Picker error: picker throws -> friendly feedback, profile unchanged',
      (tester) async {
        avatarPicker.shouldThrow = true;
        await tester.pumpWidget(
          createTestWidget(initialLocation: AppRoutes.profileEdit),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byType(InkWell).first);
        await tester.pumpAndSettle();

        expect(find.text('Failed to pick image.'), findsOneWidget);
        expect(profileRepo.saveCount, 0);
      },
    );

    testWidgets(
      'Storage error: saveAvatar throws -> repo not called, old avatar remains',
      (tester) async {
        avatarPicker.result = const PickedAvatar(
          path: 'new/path.png',
          name: 'n',
        );
        avatarStorage.shouldSaveFail = true;

        await tester.pumpWidget(
          createTestWidget(initialLocation: AppRoutes.profileEdit),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byType(InkWell).first);
        await tester.pumpAndSettle();

        final saveButton = find.text('Save Changes');
        await tester.ensureVisible(saveButton);
        await tester.tap(saveButton);
        await tester.pumpAndSettle();

        expect(avatarStorage.saveCount, 1);
        expect(profileRepo.saveCount, 0);
        expect(
          find.textContaining("We couldn't save your profile"),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Repository error after avatar copy: B created -> repo throws -> B cleanup attempted, A remains profile avatar',
      (tester) async {
        avatarPicker.result = const PickedAvatar(
          path: 'new/path.png',
          name: 'n',
        );
        profileRepo.shouldFail = true;

        await tester.pumpWidget(
          createTestWidget(initialLocation: AppRoutes.profileEdit),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byType(InkWell).first);
        await tester.pumpAndSettle();

        final saveButton = find.text('Save Changes');
        await tester.ensureVisible(saveButton);
        await tester.tap(saveButton);
        await tester.pumpAndSettle(const Duration(milliseconds: 500));

        expect(avatarStorage.saveCount, 1);
        expect(profileRepo.saveCount, 1);
        // Should have attempted to delete the new (staged) avatar
        expect(
          avatarStorage.deletedPaths,
          contains('managed/path/to/avatar_1.png'),
        );
        // Old avatar should not have been deleted
        expect(
          avatarStorage.deletedPaths,
          isNot(contains('original/path.png')),
        );
        expect(find.byType(EditProfileForm), findsOneWidget);
      },
    );

    testWidgets(
      'Success: B created -> profile saved with B -> old A cleanup attempted',
      (tester) async {
        avatarPicker.result = const PickedAvatar(
          path: 'new/path.png',
          name: 'n',
        );

        await tester.pumpWidget(
          createTestWidget(initialLocation: AppRoutes.profileEdit),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byType(InkWell).first);
        await tester.pumpAndSettle();

        final saveButton = find.text('Save Changes');
        await tester.ensureVisible(saveButton);
        await tester.tap(saveButton);
        await tester.pumpAndSettle();

        expect(profileRepo.saveCount, 1);
        expect(profileRepo.profile?.avatarUri, 'managed/path/to/avatar_1.png');
        // Old avatar A should be cleaned up
        expect(avatarStorage.deletedPaths, contains('original/path.png'));
        // Staged avatar B should NOT be cleaned up (it's now active)
        expect(
          avatarStorage.deletedPaths,
          isNot(contains('managed/path/to/avatar_1.png')),
        );
      },
    );
  });

  group('ProfileDetailsForm hardening', () {
    testWidgets('Duplicate save protection', (tester) async {
      profileRepo.saveDelay = const Duration(seconds: 1);
      await tester.pumpWidget(
        createTestWidget(initialLocation: AppRoutes.profileDetails),
      );
      await tester.pumpAndSettle();

      final saveButton = find.text('Save Details');
      await tester.ensureVisible(saveButton);

      await tester.tap(saveButton);
      await tester.tap(saveButton);
      await tester.tap(saveButton);

      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      expect(profileRepo.saveCount, 1);
    });

    testWidgets('Save failure shows error and stays on screen', (tester) async {
      profileRepo.shouldFail = true;
      await tester.pumpWidget(
        createTestWidget(initialLocation: AppRoutes.profileDetails),
      );
      await tester.pumpAndSettle();

      final saveButton = find.text('Save Details');
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(
        find.textContaining("We couldn't save your details"),
        findsOneWidget,
      );
      expect(find.byType(ProfileDetailsForm), findsOneWidget);
    });
  });
}
