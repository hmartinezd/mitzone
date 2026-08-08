import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitzone/app/theme/app_theme.dart';
import 'package:mitzone/core/identity/app_identity.dart';
import 'package:mitzone/core/identity/identity_providers.dart';
import 'package:mitzone/core/identity/identity_gateway.dart';
import 'package:mitzone/features/profile/data/avatar_picker.dart';
import 'package:mitzone/features/profile/data/avatar_storage.dart';
import 'package:mitzone/features/profile/data/profile_providers.dart';
import 'package:mitzone/features/profile/data/profile_repository.dart';
import 'package:mitzone/features/profile/domain/user_profile.dart';
import 'package:mitzone/features/profile/presentation/create_minimum_profile_screen.dart';
import 'package:mitzone/shared/widgets/mitzone_feedback_banner.dart';

class FakeIdentityGateway implements IdentityGateway {
  @override
  Future<AppIdentity> ensureIdentity() async =>
      const AppIdentity(id: 'id-123', type: AppIdentityType.localDevelopment);
  @override
  Future<AppIdentity?> getExistingIdentity() async =>
      const AppIdentity(id: 'id-123', type: AppIdentityType.localDevelopment);
}

class FakeProfileRepository implements ProfileRepository {
  int saveCallCount = 0;
  bool shouldThrow = false;
  String? lastDisplayName;
  Duration delay = const Duration(milliseconds: 10);

  @override
  Future<UserProfile?> getProfile(String identityId) async => null;

  @override
  Future<UserProfile> saveMinimumProfile({
    required String identityId,
    required String displayName,
    String? avatarUri,
  }) async {
    await Future.delayed(delay);
    if (shouldThrow) throw Exception('Save failed');
    saveCallCount++;
    lastDisplayName = displayName;
    return UserProfile(
      id: identityId,
      displayName: displayName,
      avatarUri: avatarUri,
    );
  }

  @override
  Future<UserProfile> saveProfile(UserProfile profile) async {
    await Future.delayed(delay);
    if (shouldThrow) throw Exception('Save failed');
    saveCallCount++;
    return profile;
  }
}

class FakeAvatarPicker implements AvatarPicker {
  PickedAvatar? result;
  @override
  Future<PickedAvatar?> pickFromGallery() async => result;
}

class FakeAvatarStorage implements AvatarStorage {
  bool shouldThrow = false;
  @override
  Future<String> saveAvatar({
    required String identityId,
    required String sourcePath,
  }) async {
    await Future.delayed(const Duration(milliseconds: 10));
    if (shouldThrow) throw Exception('Storage error');
    return 'file:///managed/avatar.png';
  }
}

void main() {
  group('CreateMinimumProfileScreen', () {
    late FakeIdentityGateway identityGateway;
    late FakeProfileRepository profileRepo;
    late FakeAvatarPicker avatarPicker;
    late FakeAvatarStorage avatarStorage;

    setUp(() {
      identityGateway = FakeIdentityGateway();
      profileRepo = FakeProfileRepository();
      avatarPicker = FakeAvatarPicker();
      avatarStorage = FakeAvatarStorage();
    });

    Widget createWidget() {
      return ProviderScope(
        overrides: [
          identityGatewayProvider.overrideWithValue(identityGateway),
          profileRepositoryProvider.overrideWithValue(profileRepo),
          avatarPickerProvider.overrideWithValue(avatarPicker),
          avatarStorageProvider.overrideWithValue(avatarStorage),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const CreateMinimumProfileScreen(),
        ),
      );
    }

    testWidgets('renders initial components', (tester) async {
      await tester.pumpWidget(createWidget());

      expect(find.text("Let's make Mitzone yours."), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);

      final continueButton = find.text('Continue');
      await tester.ensureVisible(continueButton);
      expect(continueButton, findsOneWidget);
    });

    testWidgets('shows validation error for empty name', (tester) async {
      await tester.pumpWidget(createWidget());

      final continueButton = find.text('Continue');
      await tester.ensureVisible(continueButton);
      await tester.tap(continueButton);
      await tester.pumpAndSettle();

      expect(find.text('Display name is required.'), findsOneWidget);
      expect(profileRepo.saveCallCount, 0);
    });

    testWidgets('successfully saves profile with valid name', (tester) async {
      // Use a longer delay to catch the loading state
      profileRepo.delay = const Duration(seconds: 2);
      await tester.pumpWidget(createWidget());

      await tester.enterText(find.byType(TextField), 'Hector');
      final continueButton = find.text('Continue');
      await tester.ensureVisible(continueButton);
      await tester.tap(continueButton);

      // Process tap and first setState
      await tester.pump();
      // Process ensurIdentity and reach first saveMinimumProfile call
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(CircularProgressIndicator), findsWidgets);

      // Complete saving (needs to exceed repo delay)
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      expect(profileRepo.saveCallCount, 1);
      expect(profileRepo.lastDisplayName, 'Hector');
    });

    testWidgets('trims whitespace from name', (tester) async {
      await tester.pumpWidget(createWidget());

      await tester.enterText(find.byType(TextField), '  Hector  ');
      final continueButton = find.text('Continue');
      await tester.ensureVisible(continueButton);
      await tester.tap(continueButton);
      await tester.pumpAndSettle();

      expect(profileRepo.lastDisplayName, 'Hector');
    });

    testWidgets('handles international names', (tester) async {
      await tester.pumpWidget(createWidget());

      await tester.enterText(find.byType(TextField), 'José Zoë 李');
      final continueButton = find.text('Continue');
      await tester.ensureVisible(continueButton);
      await tester.tap(continueButton);
      await tester.pumpAndSettle();

      expect(profileRepo.lastDisplayName, 'José Zoë 李');
    });

    testWidgets('shows error feedback on repository failure', (tester) async {
      profileRepo.shouldThrow = true;
      await tester.pumpWidget(createWidget());

      await tester.enterText(find.byType(TextField), 'Hector');
      final continueButton = find.text('Continue');
      await tester.ensureVisible(continueButton);
      await tester.tap(continueButton);
      await tester.pumpAndSettle();

      expect(
        find.text("We couldn't save your profile. Please try again."),
        findsOneWidget,
      );
      // Controls should be re-enabled
      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isTrue);
    });

    testWidgets('continues even if optional avatar storage fails', (
      tester,
    ) async {
      avatarPicker.result = const PickedAvatar(path: 'path', name: 'img.png');
      avatarStorage.shouldThrow = true;

      await tester.pumpWidget(createWidget());
      await tester.enterText(find.byType(TextField), 'Hector');
      final continueButton = find.text('Continue');
      await tester.ensureVisible(continueButton);
      await tester.tap(continueButton);

      // Process all async steps.
      // 1. Initial save
      // 2. Avatar save attempt (fails)
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(profileRepo.saveCallCount, 1);

      // Verify the feedback banner is shown
      expect(find.byType(MitzoneFeedbackBanner), findsOneWidget);
    });
  });
}
