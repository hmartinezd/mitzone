import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mitzone/core/auth/auth_providers.dart';
import 'package:mitzone/core/auth/auth_repository.dart';
import 'package:mitzone/core/auth/auth_models.dart';
import 'package:mitzone/core/config/app_config.dart';
import 'package:mitzone/core/config/app_environment.dart';
import 'package:mitzone/core/providers/core_providers.dart';
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
  int saveCount = 0;
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
    saveCount++;
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
        appConfigProvider.overrideWithValue(
          AppConfig.validated(env: AppEnvironment.local),
        ),
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

  Widget productionAccount(_AccountAuthRepository auth, {double scale = 1}) {
    final router = GoRouter(
      initialLocation: '/account',
      routes: [
        GoRoute(
          path: '/account',
          builder: (_, _) => const Scaffold(body: AccountSettingsScreen()),
        ),
        GoRoute(path: '/login', builder: (_, _) => const Text('test-login')),
      ],
    );
    addTearDown(router.dispose);
    return ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(auth)],
      child: MaterialApp.router(
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
      ),
    );
  }

  testWidgets(
    'configured account controls remain enabled at 2x; cancel does not mutate and sign-out navigates',
    (tester) async {
      final auth = _AccountAuthRepository();
      await tester.pumpWidget(productionAccount(auth, scale: 2));
      await tester.pumpAndSettle();
      for (final label in ['Sign out', 'Delete account']) {
        final control = find.widgetWithText(ListTile, label);
        await tester.ensureVisible(control);
        await tester.pumpAndSettle();
        expect(tester.widget<ListTile>(control).enabled, isTrue);
        expect(tester.widget<ListTile>(control).onTap, isNotNull);
        expect(MediaQuery.textScalerOf(tester.element(control)).scale(10), 20);
        expect(tester.takeException(), isNull);
      }
      await tester.tap(find.text('Delete account'));
      await tester.pumpAndSettle();
      expect(find.text('Delete account?'), findsOneWidget);
      expect(auth.deleteCalls, 0);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.byType(AccountSettingsScreen), findsOneWidget);
      expect(auth.deleteCalls, 0);
      expect(auth.signOutCalls, 0);
      await tester.ensureVisible(find.text('Sign out'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();
      expect(auth.signOutCalls, 1);
      expect(auth.deleteCalls, 0);
      expect(find.text('test-login'), findsOneWidget);
    },
  );

  testWidgets(
    'configured deletion requires explicit confirmation before mutation',
    (tester) async {
      final auth = _AccountAuthRepository();
      await tester.pumpWidget(productionAccount(auth));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete account'));
      await tester.pumpAndSettle();
      expect(auth.deleteCalls, 0);
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(auth.deleteCalls, 1);
      expect(auth.signOutCalls, 0);
      expect(find.text('test-login'), findsOneWidget);
    },
  );

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

    testWidgets(
      'local Account hides production actions, preserves data and supports Back',
      (tester) async {
        final before = profileRepo.profile;
        await tester.pumpWidget(
          createTestWidget(initialLocation: AppRoutes.settingsAccount),
        );
        await tester.pumpAndSettle();
        expect(find.byType(AccountSettingsScreen), findsOneWidget);
        expect(find.text('Manage your Mitzone account.'), findsOneWidget);
        expect(find.text('Sign out'), findsNothing);
        expect(find.text('Delete account'), findsNothing);
        expect(
          tester
              .widget<NavigationBar>(find.byType(NavigationBar))
              .selectedIndex,
          4,
        );
        await tester.tap(find.byTooltip('Back'));
        await tester.pumpAndSettle();
        expect(find.text('Settings'), findsOneWidget);
        expect(profileRepo.profile, same(before));
        expect(profileRepo.saveCount, 0);
      },
    );
  });
}

class _AccountAuthRepository implements AuthRepository {
  int signOutCalls = 0;
  int deleteCalls = 0;
  @override
  Future<void> signOut() async {
    signOutCalls++;
  }

  @override
  Future<void> deleteAccount() async {
    deleteCalls++;
  }

  @override
  Future<AuthSession?> restoreSession() async =>
      const AuthSession(user: AuthUser(id: 'account-test-user'));
  @override
  Stream<AuthSession?> get sessionChanges => const Stream.empty();
  @override
  Stream<bool> get recoveryEvents => const Stream.empty();
  @override
  Future<AuthSession> signIn({
    required String email,
    required String password,
  }) => throw UnimplementedError();
  @override
  Future<AuthSignUpResult> signUp({
    required String email,
    required String password,
  }) => throw UnimplementedError();
  @override
  Future<void> requestPasswordReset(String email) => throw UnimplementedError();
  @override
  Future<void> updatePassword(String password) => throw UnimplementedError();
}
