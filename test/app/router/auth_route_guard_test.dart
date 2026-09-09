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
import 'package:mitzone/features/profile/presentation/create_minimum_profile_screen.dart';
import 'package:mitzone/features/auth/presentation/login_screen.dart';
import 'package:mitzone/features/splash/presentation/splash_screen.dart';
import 'package:mitzone/features/profile/domain/user_profile.dart';
import 'package:mitzone/features/home/presentation/home_screen.dart';

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
        expect(find.byType(CreateMinimumProfileScreen), findsNothing);
      },
    );

    testWidgets('configured session without profile routes to create profile', (
      tester,
    ) async {
      auth.session = const AuthSession(user: AuthUser(id: 'user-1'));
      profiles.profile = null;
      await tester.pumpWidget(buildApp());
      await completeSplash(tester);

      expect(find.byType(CreateMinimumProfileScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
    });

    testWidgets('direct protected routes redirect without a session', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildApp(initialLocation: AppRoutes.createProfile),
      );
      await completeSplash(tester);

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(CreateMinimumProfileScreen), findsNothing);
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
      await tester.pumpWidget(
        buildApp(initialLocation: AppRoutes.createProfile),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CreateMinimumProfileScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
    });

    testWidgets('session loss redirects an authenticated route to login', (
      tester,
    ) async {
      auth.session = const AuthSession(user: AuthUser(id: 'user-1'));
      await tester.pumpWidget(
        buildApp(initialLocation: AppRoutes.createProfile),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CreateMinimumProfileScreen), findsOneWidget);

      auth.emit(null);
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(CreateMinimumProfileScreen), findsNothing);
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

      expect(find.byType(CreateMinimumProfileScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
    });

    testWidgets('session loading does not redirect to login prematurely', (
      tester,
    ) async {
      final restore = Completer<AuthSession?>();
      auth.restoreCompleter = restore;
      await tester.pumpWidget(
        buildApp(initialLocation: AppRoutes.createProfile),
      );
      await tester.pump();

      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);

      restore.complete(null);
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });

  testWidgets('local mode keeps the existing local entry behavior', (
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

    expect(find.byType(CreateMinimumProfileScreen), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
  });
}

class FakeAuthRepository implements AuthRepository {
  AuthSession? session;
  Completer<AuthSession?>? restoreCompleter;
  final _changes = StreamController<AuthSession?>.broadcast();

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
  }) async => UserProfile(
    id: identityId,
    displayName: displayName,
    avatarUri: avatarUri,
  );

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
