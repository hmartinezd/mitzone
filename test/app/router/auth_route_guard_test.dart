import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitzone/app/router/app_routes.dart';
import 'package:mitzone/app/router/app_router.dart';
import 'package:mitzone/app/theme/app_theme.dart';
import 'package:mitzone/core/auth/auth_models.dart';
import 'package:mitzone/core/auth/auth_providers.dart';
import 'package:mitzone/core/auth/auth_repository.dart';
import 'package:mitzone/core/config/app_config.dart';
import 'package:mitzone/core/config/app_environment.dart';
import 'package:mitzone/core/identity/app_identity.dart';
import 'package:mitzone/core/identity/identity_gateway.dart';
import 'package:mitzone/core/identity/identity_providers.dart';
import 'package:mitzone/core/providers/core_providers.dart';
import 'package:mitzone/features/onboarding/data/onboarding_providers.dart';
import 'package:mitzone/features/onboarding/data/onboarding_status_store.dart';
import 'package:mitzone/features/onboarding/presentation/onboarding_screen.dart';
import 'package:mitzone/features/profile/data/profile_providers.dart';
import 'package:mitzone/features/profile/data/profile_repository.dart';
import 'package:mitzone/features/auth/presentation/login_screen.dart';
import 'package:mitzone/features/splash/presentation/splash_screen.dart';
import 'package:mitzone/features/profile/domain/user_profile.dart';
import 'package:mitzone/features/home/presentation/home_screen.dart';
import 'package:mitzone/core/storage/storage_providers.dart';
import 'package:mitzone/features/chat/data/chat_providers.dart';
import 'package:mitzone/features/connections/data/connection_providers.dart';
import 'package:mitzone/features/encounters/data/encounter_providers.dart';
import 'package:mitzone/features/discovery/data/discovery_providers.dart';
import '../../support/memory_local_storage.dart';
import 'package:mitzone/features/profile/presentation/profile_screen.dart';
import 'package:mitzone/features/foundation/presentation/entry_failure_screen.dart';

void main() {
  group('configured application route policy', () {
    late FakeAuthRepository auth;
    late FakeOnboardingStore onboarding;
    late FakeProfileRepository profiles;
    late FakeIdentityGateway identity;

    setUp(() {
      auth = FakeAuthRepository();
      onboarding = FakeOnboardingStore()..completed = true;
      profiles = FakeProfileRepository();
      identity = FakeIdentityGateway();
    });

    tearDown(() async {
      await auth.dispose();
    });

    Widget buildApp({String initialLocation = AppRoutes.splash}) {
      return ProviderScope(
        overrides: [
          localStorageProvider.overrideWithValue(MemoryLocalStorage()),
          homeDiscoveryInterestsProvider.overrideWithValue(const <String>{}),
          nearbyDiscoveryProvider(
            const <String>{},
          ).overrideWithValue(const AsyncValue.data([])),
          encountersForCurrentUserProvider.overrideWithValue(
            const AsyncValue.data([]),
          ),
          incomingConnectionRequestsProvider.overrideWithValue(
            const AsyncValue.data([]),
          ),
          connectionsProvider.overrideWithValue(const AsyncValue.data([])),
          chatConversationsProvider.overrideWithValue(
            const AsyncValue.data([]),
          ),
          appConfigProvider.overrideWithValue(
            AppConfig.validated(
              env: AppEnvironment.development,
              supabaseUrl: 'https://test.supabase.co',
              supabasePublishableKey: 'sb_publishable_test',
            ),
          ),
          authRepositoryProvider.overrideWithValue(auth),
          onboardingStatusStoreProvider.overrideWithValue(onboarding),
          profileRepositoryProvider.overrideWithValue(profiles),
          identityGatewayProvider.overrideWithValue(identity),
          routerInitialLocationProvider.overrideWithValue(initialLocation),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            return MaterialApp.router(
              theme: AppTheme.darkTheme,
              routerConfig: ref.watch(routerProvider),
            );
          },
        ),
      );
    }

    Future<void> completeSplash(WidgetTester tester) async {
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
    }

    testWidgets('configured first install without session shows onboarding', (
      tester,
    ) async {
      onboarding.completed = false;
      await tester.pumpWidget(buildApp());
      await completeSplash(tester);

      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
    });

    testWidgets('configured onboarded install without session shows login', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp());
      await completeSplash(tester);

      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets(
      'completing onboarding in configured mode routes to login without a session',
      (tester) async {
        onboarding.completed = false;
        await tester.pumpWidget(
          buildApp(initialLocation: AppRoutes.onboarding),
        );
        await tester.pump();

        await tester.tap(find.text('Skip'));
        await tester.pumpAndSettle();

        expect(onboarding.completed, isTrue);
        expect(find.byType(LoginScreen), findsOneWidget);
        expect(find.byType(HomeScreen), findsNothing);
      },
    );

    testWidgets(
      'configured session without profile creates a minimum profile and opens Home',
      (tester) async {
        auth.session = const AuthSession(user: AuthUser(id: 'user-1'));
        profiles.profile = null;
        await tester.pumpWidget(buildApp());
        await completeSplash(tester);

        expect(find.byType(HomeScreen), findsOneWidget);
        expect(profiles.profile?.id, 'user-1');
        expect(profiles.profile?.displayName, 'Mitzone User');
        expect(find.byType(LoginScreen), findsNothing);
      },
    );

    testWidgets('direct protected routes redirect without a session', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp(initialLocation: AppRoutes.profile));
      await completeSplash(tester);

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
    });

    testWidgets('direct application shell route redirects without a session', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp(initialLocation: AppRoutes.home));
      await completeSplash(tester);

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
    });

    testWidgets('nested protected routes redirect without a session', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildApp(initialLocation: AppRoutes.settingsAccount),
      );
      await completeSplash(tester);

      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('authenticated session can access protected profile route', (
      tester,
    ) async {
      auth.session = const AuthSession(user: AuthUser(id: 'user-1'));
      await tester.pumpWidget(buildApp(initialLocation: AppRoutes.profile));
      // Restoration routes through Splash and the normal Home entry policy.
      await completeSplash(tester);
      ProviderScope.containerOf(
        tester.element(find.byType(HomeScreen)),
      ).read(routerProvider).go(AppRoutes.profile);
      await tester.pumpAndSettle();

      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
    });

    testWidgets('session loss redirects an authenticated route to login', (
      tester,
    ) async {
      auth.session = const AuthSession(user: AuthUser(id: 'user-1'));
      await tester.pumpWidget(buildApp(initialLocation: AppRoutes.profile));
      // Restoration routes through Splash and the normal Home entry policy.
      await completeSplash(tester);
      ProviderScope.containerOf(
        tester.element(find.byType(HomeScreen)),
      ).read(routerProvider).go(AppRoutes.profile);
      await tester.pumpAndSettle();
      expect(find.byType(ProfileScreen), findsOneWidget);

      auth.emit(null);
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(ProfileScreen), findsNothing);
    });

    testWidgets('authenticated session arriving on login uses entry policy', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp(initialLocation: AppRoutes.login));
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);

      auth.session = const AuthSession(user: AuthUser(id: 'user-1'));
      auth.emit(auth.session);
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
    });

    testWidgets('session loading does not redirect to login prematurely', (
      tester,
    ) async {
      final restore = Completer<AuthSession?>();
      auth.restoreCompleter = restore;
      await tester.pumpWidget(buildApp(initialLocation: AppRoutes.profile));
      await tester.pump();

      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);

      restore.complete(null);
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });

  testWidgets('local entry without authentication fails closed', (
    tester,
  ) async {
    final onboarding = FakeOnboardingStore()..completed = true;
    final profiles = FakeProfileRepository();
    final identity = FakeIdentityGateway();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(
            AppConfig.validated(env: AppEnvironment.local),
          ),
          onboardingStatusStoreProvider.overrideWithValue(onboarding),
          profileRepositoryProvider.overrideWithValue(profiles),
          identityGatewayProvider.overrideWithValue(identity),
        ],
        child: Consumer(
          builder: (context, ref, _) => MaterialApp.router(
            theme: AppTheme.darkTheme,
            routerConfig: ref.watch(routerProvider),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.byType(EntryFailureScreen), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
  });
}

class FakeAuthRepository implements AuthRepository {
  AuthSession? session;
  Completer<AuthSession?>? restoreCompleter;
  final _changes = StreamController<AuthSession?>.broadcast();

  // These tests do not exercise recovery or account deletion. Fail explicitly
  // if either operation is used instead of simulating a successful mutation.
  @override
  Future<void> requestPasswordReset(String email) async =>
      throw UnimplementedError('Password recovery is unavailable.');
  @override
  Future<void> updatePassword(String password) async =>
      throw UnimplementedError('Password reset is unavailable.');
  @override
  Future<void> deleteAccount() async =>
      throw UnimplementedError('Account deletion is unavailable.');
  @override
  Stream<bool> get recoveryEvents => const Stream<bool>.empty();

  @override
  Future<AuthSession?> restoreSession() =>
      restoreCompleter?.future ?? Future.value(session);

  @override
  Future<AuthSession> signIn({
    required String email,
    required String password,
  }) async {
    session = AuthSession(
      user: AuthUser(id: 'user-1', email: email),
    );
    emit(session);
    return session!;
  }

  @override
  Future<AuthSignUpResult> signUp({
    required String email,
    required String password,
  }) async {
    session = AuthSession(
      user: AuthUser(id: 'user-1', email: email),
    );
    emit(session);
    return AuthSignUpResult(
      user: session!.user,
      session: session,
      outcome: AuthSignUpOutcome.signedIn,
    );
  }

  @override
  Future<void> signOut() async {
    session = null;
    emit(null);
  }

  @override
  Stream<AuthSession?> get sessionChanges => _changes.stream;

  void emit(AuthSession? value) {
    session = value;
    _changes.add(value);
  }

  Future<void> dispose() => _changes.close();
}

class FakeOnboardingStore implements OnboardingStatusStore {
  bool completed = false;

  @override
  Future<bool> isCompleted() async => completed;

  @override
  Future<void> markCompleted() async => completed = true;
}

class FakeProfileRepository implements ProfileRepository {
  UserProfile? profile;

  @override
  Future<UserProfile?> getProfile(String identityId) async => profile;

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
  Future<UserProfile> saveProfile(UserProfile profile) async => profile;
}

class FakeIdentityGateway implements IdentityGateway {
  @override
  Future<AppIdentity> ensureIdentity() async => const AppIdentity(
    id: 'local-user',
    type: AppIdentityType.localDevelopment,
  );

  @override
  Future<AppIdentity?> getExistingIdentity() async => const AppIdentity(
    id: 'local-user',
    type: AppIdentityType.localDevelopment,
  );
}
