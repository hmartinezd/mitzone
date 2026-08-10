import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitzone/app/router/app_router.dart';
import 'package:mitzone/app/router/app_routes.dart';
import 'package:mitzone/core/identity/app_identity.dart';
import 'package:mitzone/core/identity/identity_gateway.dart';
import 'package:mitzone/core/identity/identity_providers.dart';
import 'package:mitzone/features/onboarding/data/onboarding_providers.dart';
import 'package:mitzone/features/onboarding/data/onboarding_status_store.dart';
import 'package:mitzone/features/profile/domain/user_profile.dart';
import 'package:mitzone/features/profile/data/profile_providers.dart';
import 'package:mitzone/features/profile/data/profile_repository.dart';
import 'package:mitzone/features/profile/presentation/edit_profile_screen.dart';
import 'package:mitzone/features/profile/presentation/profile_details_screen.dart';
import 'package:mitzone/features/profile/presentation/profile_screen.dart';
import 'package:mitzone/features/profile/presentation/settings_screen.dart';
import 'package:mitzone/features/profile/presentation/settings_placeholders.dart';

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
  }) async {
    final newProfile = UserProfile(
      id: identityId,
      displayName: displayName,
      avatarUri: avatarUri,
    );
    profile = newProfile;
    return newProfile;
  }

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

void main() {
  late MockOnboardingStore onboardingStore;
  late MockIdentityGateway identityGateway;
  late MockProfileRepository profileRepo;

  setUp(() {
    onboardingStore = MockOnboardingStore();
    identityGateway = MockIdentityGateway();
    profileRepo = MockProfileRepository();
  });

  Widget createTestWidget({String? initialLocation, double textScale = 1.0}) {
    return ProviderScope(
      overrides: [
        onboardingStatusStoreProvider.overrideWithValue(onboardingStore),
        identityGatewayProvider.overrideWithValue(identityGateway),
        profileRepositoryProvider.overrideWithValue(profileRepo),
        if (initialLocation != null)
          routerInitialLocationProvider.overrideWithValue(initialLocation),
      ],
      child: Consumer(
        builder: (context, ref, _) {
          final router = ref.watch(routerProvider);
          return MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
            child: MaterialApp.router(routerConfig: router),
          );
        },
      ),
    );
  }

  group('Profile Hardening', () {
    testWidgets('Edit Profile -> Back returns to Profile', (tester) async {
      await tester.pumpWidget(
        createTestWidget(initialLocation: AppRoutes.profileEdit),
      );
      await tester.pumpAndSettle();

      expect(find.byType(EditProfileForm), findsOneWidget);

      final backButton = find.byTooltip('Back');
      expect(backButton, findsOneWidget);

      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(find.byType(ProfileScreen), findsOneWidget);
      // NavigationBar should show index 4
      final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(navBar.selectedIndex, 4);
    });

    testWidgets('Profile Details -> Back returns to Profile', (tester) async {
      await tester.pumpWidget(
        createTestWidget(initialLocation: AppRoutes.profileDetails),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ProfileDetailsForm), findsOneWidget);

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      expect(find.byType(ProfileScreen), findsOneWidget);
    });

    testWidgets('Settings subpages -> Back returns to Settings', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(initialLocation: AppRoutes.settingsAccount),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AccountSettingsScreen), findsOneWidget);

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('Home reflects profile name updates without restart', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(initialLocation: AppRoutes.home),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Hector'), findsOneWidget);

      // Navigate to Edit Profile
      await tester.tap(find.byIcon(Icons.person_outline)); // Profile tab
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit profile'));
      await tester.pumpAndSettle();

      // Change name
      await tester.enterText(find.byType(TextFormField), 'Hector Updated');
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      // Go back to Home
      await tester.tap(find.byIcon(Icons.home_outlined));
      await tester.pumpAndSettle();

      expect(find.textContaining('Hector Updated'), findsOneWidget);
    });

    testWidgets('Duplicate save protection in EditProfileForm', (tester) async {
      profileRepo.saveDelay = const Duration(seconds: 1);
      await tester.pumpWidget(
        createTestWidget(initialLocation: AppRoutes.profileEdit),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save Changes'));
      await tester.tap(find.text('Save Changes'));
      await tester.tap(find.text('Save Changes'));

      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      expect(profileRepo.saveCount, 1);
    });

    testWidgets(
      'Save failure in EditProfileForm shows error and stays on screen',
      (tester) async {
        profileRepo.shouldFail = true;
        await tester.pumpWidget(
          createTestWidget(initialLocation: AppRoutes.profileEdit),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Save Changes'));
        await tester.pumpAndSettle();

        expect(
          find.textContaining("We couldn't save your profile"),
          findsOneWidget,
        );
        expect(find.byType(EditProfileForm), findsOneWidget);
      },
    );

    testWidgets('Interest validation feedback (>10 items)', (tester) async {
      await tester.pumpWidget(
        createTestWidget(initialLocation: AppRoutes.profileDetails),
      );
      await tester.pumpAndSettle();

      final interestsField = find.byKey(const Key('interests_field'));

      await tester.enterText(interestsField, '1,2,3,4,5,6,7,8,9,10,11');
      await tester.pumpAndSettle();

      expect(find.text('Add up to 10 interests.'), findsOneWidget);
    });

    testWidgets('Interest validation feedback (>30 chars item)', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(initialLocation: AppRoutes.profileDetails),
      );
      await tester.pumpAndSettle();

      final interestsField = find.byKey(const Key('interests_field'));

      await tester.enterText(interestsField, 'A' * 31);
      await tester.pumpAndSettle();

      expect(
        find.text('Each interest must be 30 characters or fewer.'),
        findsOneWidget,
      );
    });

    testWidgets(
      'ProfileDetails responsiveness at 320x480 with 2.0 text scale',
      (tester) async {
        tester.view.physicalSize = const Size(320, 480);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          createTestWidget(
            initialLocation: AppRoutes.profileDetails,
            textScale: 2.0,
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);

        // Connection goal chips should be visible (might need scroll)
        final scrollable = find.byType(Scrollable).first;
        await tester.drag(scrollable, const Offset(0, -500));
        await tester.pump();

        expect(find.text('Connection Goal'), findsOneWidget);
        expect(find.text('Social'), findsOneWidget);
      },
    );
  });
}
