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
import 'package:mitzone/core/providers/core_providers.dart';
import 'package:mitzone/features/onboarding/data/onboarding_providers.dart';
import 'package:mitzone/features/onboarding/data/onboarding_status_store.dart';
import 'package:mitzone/features/profile/data/profile_providers.dart';
import 'package:mitzone/features/profile/data/profile_repository.dart';
import 'package:mitzone/features/profile/domain/user_profile.dart';
import 'package:mitzone/features/home/presentation/home_screen.dart';

void main() {
  test('stream provider exposes its restored session through future', () async {
    final auth = _FakeAuthRepository()
      ..session = const AuthSession(user: AuthUser(id: 'user-1'));
    addTearDown(auth.dispose);
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(auth)],
    );
    addTearDown(container.dispose);
    container.listen(authSessionProvider, (_, _) {}, fireImmediately: true);

    expect(
      await container.read(authSessionProvider.future).timeout(
        const Duration(seconds: 1),
      ),
      isNotNull,
    );
  });

  testWidgets('sign-in waits for auth state before navigating home', (
    tester,
  ) async {
    final auth = _FakeAuthRepository();
    addTearDown(auth.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(
            AppConfig.validated(
              env: AppEnvironment.development,
              supabaseUrl: 'https://test.supabase.co',
              supabasePublishableKey: 'sb_publishable_test',
            ),
          ),
          authRepositoryProvider.overrideWithValue(auth),
          onboardingStatusStoreProvider.overrideWithValue(
            _CompletedOnboardingStore(),
          ),
          profileRepositoryProvider.overrideWithValue(
            _ProfileRepository(),
          ),
          routerInitialLocationProvider.overrideWithValue(AppRoutes.login),
        ],
        child: Consumer(
          builder: (context, ref, _) => MaterialApp.router(
            theme: AppTheme.darkTheme,
            routerConfig: ref.watch(routerProvider),
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField).at(0), 'user@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'password');
    await tester.tap(find.text('Sign In').last);
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(find.byType(HomeScreen), findsOneWidget);
  });
}

class _FakeAuthRepository implements AuthRepository {
  final _changes = StreamController<AuthSession?>.broadcast();
  AuthSession? session;

  @override
  Future<AuthSession?> restoreSession() async {
    return session;
  }

  @override
  Future<AuthSession> signIn({
    required String email,
    required String password,
  }) async {
    session = AuthSession(user: AuthUser(id: 'user-1', email: email));
    _changes.add(session);
    return session!;
  }

  @override
  Future<AuthSignUpResult> signUp({
    required String email,
    required String password,
  }) => throw UnimplementedError();

  @override
  Future<void> signOut() async {
    session = null;
    _changes.add(null);
  }

  @override
  Future<void> requestPasswordReset(String email) async {}

  @override
  Future<void> updatePassword(String password) async {}

  @override
  Future<void> deleteAccount() async {}

  @override
  Stream<AuthSession?> get sessionChanges => _changes.stream;

  @override
  Stream<bool> get recoveryEvents => const Stream<bool>.empty();

  Future<void> dispose() => _changes.close();
}

class _CompletedOnboardingStore implements OnboardingStatusStore {
  @override
  Future<bool> isCompleted() async => true;

  @override
  Future<void> markCompleted() async {}
}

class _ProfileRepository implements ProfileRepository {
  @override
  Future<UserProfile?> getProfile(String identityId) async =>
      const UserProfile(id: 'user-1', displayName: 'Test User');

  @override
  Future<UserProfile> saveMinimumProfile({
    required String identityId,
    required String displayName,
    String? avatarUri,
  }) async => UserProfile(id: identityId, displayName: displayName);

  @override
  Future<UserProfile> saveProfile(UserProfile profile) async => profile;
}
