import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitzone/app/router/app_routes.dart';
import 'package:mitzone/core/identity/app_identity.dart';
import 'package:mitzone/core/identity/identity_gateway.dart';
import 'package:mitzone/core/identity/identity_providers.dart';
import 'package:mitzone/features/onboarding/data/onboarding_providers.dart';
import 'package:mitzone/features/onboarding/data/onboarding_status_store.dart';
import 'package:mitzone/features/profile/data/profile_providers.dart';
import 'package:mitzone/features/profile/data/profile_repository.dart';
import 'package:mitzone/features/profile/domain/user_profile.dart';
import 'package:mitzone/app/router/app_router.dart';
import 'package:mitzone/features/navigation/presentation/main_navigation_shell.dart';
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

  Widget createTestWidget({String? initialLocation}) {
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
          return MaterialApp.router(routerConfig: router);
        },
      ),
    );
  }

  group('Profile Nested Route Matrix', () {
    final routes = [
      AppRoutes.profileEdit,
      AppRoutes.profileDetails,
      AppRoutes.settings,
      AppRoutes.settingsAccount,
      AppRoutes.settingsPrivacy,
      AppRoutes.settingsNotifications,
      AppRoutes.settingsTerms,
      AppRoutes.settingsPrivacyPolicy,
    ];

    for (final route in routes) {
      testWidgets('Direct entry to $route', (tester) async {
        await tester.pumpWidget(createTestWidget(initialLocation: route));
        await tester.pumpAndSettle();

        expect(find.byType(MainNavigationShell), findsOneWidget);
        final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
        expect(navBar.selectedIndex, 4);
      });
    }

    testWidgets('Settings child routes Back -> Settings', (tester) async {
      await tester.pumpWidget(
        createTestWidget(initialLocation: AppRoutes.settingsAccount),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
    });
  });

  group('Settings Content', () {
    testWidgets('Exercise all settings placeholders', (tester) async {
      final settings = {
        AppRoutes.settingsAccount: AccountSettingsScreen,
        AppRoutes.settingsPrivacy: PrivacySettingsScreen,
        AppRoutes.settingsNotifications: NotificationsSettingsScreen,
        AppRoutes.settingsTerms: TermsSettingsScreen,
        AppRoutes.settingsPrivacyPolicy: PrivacyPolicySettingsScreen,
      };

      for (final entry in settings.entries) {
        await tester.pumpWidget(createTestWidget(initialLocation: entry.key));
        await tester.pumpAndSettle();
        expect(find.byType(entry.value), findsOneWidget);
      }
    });

    testWidgets('Account actions are disabled and do not mutate', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(initialLocation: AppRoutes.settingsAccount),
      );
      await tester.pumpAndSettle();

      final signOut = find.text('Sign out');
      final delete = find.text('Delete account');

      expect(signOut, findsOneWidget);
      expect(delete, findsOneWidget);

      await tester.tap(signOut);
      await tester.pumpAndSettle();
      // Should still be on Account settings
      expect(find.byType(AccountSettingsScreen), findsOneWidget);

      await tester.tap(delete);
      await tester.pumpAndSettle();
      expect(find.byType(AccountSettingsScreen), findsOneWidget);
    });
  });
}
