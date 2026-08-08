import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitzone/app/router/app_router.dart';
import 'package:mitzone/app/router/app_routes.dart';
import 'package:mitzone/features/profile/data/profile_providers.dart';
import 'package:mitzone/features/profile/data/avatar_picker.dart';
import 'package:mitzone/features/profile/data/avatar_storage.dart';
import 'package:mitzone/features/profile/data/profile_repository.dart';
import 'package:mitzone/features/profile/domain/user_profile.dart';

class FakeProfileRepository implements ProfileRepository {
  UserProfile? profile;
  int saveCount = 0;

  @override
  Future<UserProfile?> getProfile(String id) async => profile;

  @override
  Future<UserProfile> saveMinimumProfile({
    required String identityId,
    required String displayName,
    String? avatarUri,
  }) async {
    return profile!;
  }

  @override
  Future<UserProfile> saveProfile(UserProfile p) async {
    saveCount++;
    profile = p;
    return p;
  }
}

class FakeAvatarPicker implements AvatarPicker {
  PickedAvatar? result;
  @override
  Future<PickedAvatar?> pickFromGallery() async => result;
}

class FakeAvatarStorage implements AvatarStorage {
  @override
  Future<String> saveAvatar({
    required String identityId,
    required String sourcePath,
  }) async {
    return 'managed_$sourcePath';
  }

  @override
  Future<void> deleteAvatar({
    required String identityId,
    required String avatarPath,
  }) async {}
}

void main() {
  late FakeProfileRepository repo;
  late FakeAvatarPicker picker;
  late FakeAvatarStorage storage;

  setUp(() {
    repo = FakeProfileRepository();
    picker = FakeAvatarPicker();
    storage = FakeAvatarStorage();
    repo.profile = const UserProfile(id: '1', displayName: 'Hector');
  });

  Widget createWidget(String location) {
    return ProviderScope(
      overrides: [
        currentProfileProvider.overrideWith((ref) => repo.getProfile('1')),
        profileRepositoryProvider.overrideWithValue(repo),
        avatarPickerProvider.overrideWithValue(picker),
        avatarStorageProvider.overrideWithValue(storage),
        routerInitialLocationProvider.overrideWithValue(location),
      ],
      child: Consumer(
        builder: (context, ref, _) {
          return MaterialApp.router(routerConfig: ref.watch(routerProvider));
        },
      ),
    );
  }

  group('ProfileScreen', () {
    testWidgets('renders profile info and completion', (tester) async {
      await tester.pumpWidget(createWidget(AppRoutes.profile));
      await tester.pumpAndSettle();

      expect(find.text('Hector'), findsOneWidget);
      expect(find.text('14%'), findsOneWidget);
      expect(find.text('Edit profile'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('navigates to Edit Profile', (tester) async {
      await tester.pumpWidget(createWidget(AppRoutes.profile));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Edit profile'));
      await tester.pumpAndSettle();

      expect(find.text('Basic Identity'), findsOneWidget);
    });
  });

  group('EditProfileScreen', () {
    testWidgets('validates name length', (tester) async {
      await tester.pumpWidget(createWidget(AppRoutes.profileEdit));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'A');
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      expect(find.text('Minimum 2 characters'), findsOneWidget);
      expect(repo.saveCount, 0);
    });

    testWidgets('saves name changes', (tester) async {
      await tester.pumpWidget(createWidget(AppRoutes.profileEdit));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'Hector Updated');
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      expect(repo.saveCount, 1);
      expect(repo.profile?.displayName, 'Hector Updated');
    });
  });

  group('ProfileDetailsScreen', () {
    testWidgets('saves optional fields and connection goal', (tester) async {
      await tester.pumpWidget(createWidget(AppRoutes.profileDetails));
      await tester.pumpAndSettle();

      final scrollable = find.byType(Scrollable).first;

      await tester.enterText(
        find.widgetWithText(TextFormField, 'City'),
        'Tampa',
      );

      await tester.scrollUntilVisible(
        find.text('Social'),
        100,
        scrollable: scrollable,
      );
      await tester.tap(find.text('Social'));

      await tester.scrollUntilVisible(
        find.text('Save Details'),
        100,
        scrollable: scrollable,
      );
      await tester.tap(find.text('Save Details'));
      await tester.pumpAndSettle();

      expect(repo.saveCount, 1);
      expect(repo.profile?.city, 'Tampa');
      expect(repo.profile?.connectionGoal, ConnectionGoal.social);
    });

    testWidgets('normalizes interests', (tester) async {
      await tester.pumpWidget(createWidget(AppRoutes.profileDetails));
      await tester.pumpAndSettle();

      final scrollable = find.byType(Scrollable).first;

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Interests'),
        ' Flutter, dart , Flutter ',
      );

      await tester.scrollUntilVisible(
        find.text('Save Details'),
        100,
        scrollable: scrollable,
      );
      await tester.tap(find.text('Save Details'));
      await tester.pumpAndSettle();

      expect(repo.profile?.interests, ['Flutter', 'dart']);
    });
  });

  group('SettingsScreen', () {
    testWidgets('renders all categories', (tester) async {
      await tester.pumpWidget(createWidget(AppRoutes.settings));
      await tester.pumpAndSettle();

      expect(find.text('GENERAL'), findsOneWidget);
      expect(find.text('ABOUT'), findsOneWidget);
      expect(find.text('ACCOUNT ACTIONS'), findsOneWidget);
      expect(find.text('Sign out'), findsOneWidget);
      expect(find.text('Delete account'), findsOneWidget);
    });

    testWidgets('account actions are disabled', (tester) async {
      await tester.pumpWidget(createWidget(AppRoutes.settings));
      await tester.pumpAndSettle();

      final signOutFinder = find.ancestor(
        of: find.text('Sign out'),
        matching: find.byType(ListTile),
      );
      final signOut = tester.widget<ListTile>(signOutFinder);
      expect(signOut.enabled, isFalse);
    });
  });
}
