import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitzone/app/router/app_router.dart';
import 'package:mitzone/app/router/app_routes.dart';
import 'package:mitzone/core/config/app_config.dart';
import 'package:mitzone/core/config/app_environment.dart';
import 'package:mitzone/core/providers/core_providers.dart';
import 'package:mitzone/features/home/presentation/home_screen.dart';
import 'package:mitzone/features/chat/data/chat_providers.dart';
import 'package:mitzone/features/connections/data/connection_providers.dart';
import 'package:mitzone/features/encounters/data/encounter_providers.dart';
import 'package:mitzone/features/discovery/data/discovery_providers.dart';
import 'package:mitzone/app/theme/app_theme.dart';
import 'package:mitzone/core/auth/auth_models.dart';
import 'package:mitzone/core/auth/auth_providers.dart';
import 'package:mitzone/core/auth/auth_repository.dart';
import 'package:mitzone/core/errors/domain_error.dart';
import 'package:mitzone/features/profile/data/profile_providers.dart';
import 'package:mitzone/features/onboarding/data/onboarding_providers.dart';
import 'package:mitzone/features/onboarding/data/onboarding_status_store.dart';
import 'package:mitzone/core/storage/storage_providers.dart';
import '../../support/memory_local_storage.dart';
import 'package:mitzone/features/profile/data/profile_repository.dart';
import 'package:mitzone/features/profile/domain/user_profile.dart';
import 'package:mitzone/shared/widgets/mitzone_button.dart';

void main() {
  group('LoginScreen', () {
    late FakeAuthRepository auth;
    late FakeProfileRepository profiles;

    setUp(() {
      auth = FakeAuthRepository();
      profiles = FakeProfileRepository();
    });

    tearDown(() async => auth.dispose());

    Widget buildTestWidget() {
      return ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(
            AppConfig.validated(env: AppEnvironment.local),
          ),
          routerInitialLocationProvider.overrideWithValue(AppRoutes.login),
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
          localStorageProvider.overrideWithValue(MemoryLocalStorage()),
          onboardingStatusStoreProvider.overrideWithValue(
            _CompletedOnboardingStore(),
          ),
          authRepositoryProvider.overrideWithValue(auth),
          profileRepositoryProvider.overrideWithValue(profiles),
        ],
        child: Consumer(
          builder: (context, ref, _) => MaterialApp.router(
            theme: AppTheme.darkTheme,
            routerConfig: ref.watch(routerProvider),
          ),
        ),
      );
    }

    Future<void> switchToSignUp(WidgetTester tester) async {
      await tester.tap(find.text('Create Account').first);
      await tester.pumpAndSettle();
    }

    Future<void> enterValidSignup(WidgetTester tester) async {
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'new@example.com');
      await tester.enterText(fields.at(1), 'a password');
      await tester.enterText(fields.at(2), 'a password');
    }

    Future<void> tapButton(WidgetTester tester, String text) async {
      final button = find.widgetWithText(MitzoneButton, text);
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pump();
    }

    testWidgets('defaults to sign in and switches to account creation', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('Sign In'), findsWidgets);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Confirm password'), findsNothing);

      await switchToSignUp(tester);

      expect(find.text('Create your Mitzone account'), findsOneWidget);
      expect(find.text('Confirm password'), findsOneWidget);
      expect(
        find.widgetWithText(MitzoneButton, 'Create Account'),
        findsOneWidget,
      );

      await tester.tap(find.text('Sign In').first);
      await tester.pumpAndSettle();
      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('Confirm password'), findsNothing);
    });

    testWidgets('validates email, empty password, and mismatched passwords', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await switchToSignUp(tester);

      await tester.enterText(find.byType(TextFormField).at(0), 'not-an-email');
      await tapButton(tester, 'Create Account');
      expect(find.text('Enter a valid email address.'), findsOneWidget);
      expect(auth.signUpCalls, 0);

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'new@example.com',
      );
      await tapButton(tester, 'Create Account');
      expect(find.text('Password is required.'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).at(1), 'first');
      await tester.enterText(find.byType(TextFormField).at(2), 'second');
      await tapButton(tester, 'Create Account');
      expect(find.text('Passwords do not match.'), findsOneWidget);
      expect(auth.signUpCalls, 0);
    });

    testWidgets('password visibility controls reveal each password field', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await switchToSignUp(tester);

      expect(
        tester
            .widget<EditableText>(find.byType(EditableText).at(1))
            .obscureText,
        isTrue,
      );
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText).at(2))
            .obscureText,
        isTrue,
      );
      await tester.tap(find.byTooltip('Show password').first);
      await tester.pump();
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText).at(1))
            .obscureText,
        isFalse,
      );
    });

    testWidgets(
      'confirmation-required signup stays on the confirmation state',
      (tester) async {
        auth.signupResult = AuthSignUpResult(
          user: const AuthUser(id: 'user-1', email: 'new@example.com'),
          outcome: AuthSignUpOutcome.confirmationRequired,
        );
        await tester.pumpWidget(buildTestWidget());
        await switchToSignUp(tester);
        await enterValidSignup(tester);

        await tapButton(tester, 'Create Account');
        await tester.pumpAndSettle();

        expect(find.text('Check your email'), findsOneWidget);
        expect(find.textContaining('new@example.com'), findsOneWidget);
        expect(find.byType(HomeScreen), findsNothing);
        expect(auth.signUpCalls, 1);

        await tapButton(tester, 'Back to Sign In');
        await tester.pumpAndSettle();
        expect(find.text('Welcome back'), findsOneWidget);
        expect(find.byType(TextFormField), findsNWidgets(2));
        expect(find.text('new@example.com'), findsOneWidget);
      },
    );

    testWidgets('immediate signup creates a minimum profile and routes home', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await switchToSignUp(tester);
      await enterValidSignup(tester);

      await tapButton(tester, 'Create Account');
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(profiles.requestedId, 'user-1');
      expect(profiles.profile?.id, 'user-1');
      expect(profiles.profile?.displayName, 'new');
    });

    testWidgets('existing profile routes to home after sign in', (
      tester,
    ) async {
      profiles.profile = const UserProfile(id: 'user-1', displayName: 'User');
      await tester.pumpWidget(buildTestWidget());
      await tester.enterText(
        find.byType(TextFormField).at(0),
        ' user@example.com ',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'password');
      await tapButton(tester, 'Sign In');
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(auth.signInEmail, 'user@example.com');
    });

    testWidgets('presents safe messages for sign-in and signup failures', (
      tester,
    ) async {
      auth.signInError = const DomainError(
        DomainErrorCode.unauthorized,
        'raw backend details',
      );
      await tester.pumpWidget(buildTestWidget());
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'user@example.com',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'password');
      await tapButton(tester, 'Sign In');
      expect(
        find.text(
          'We could not sign you in. Check your details and try again.',
        ),
        findsOneWidget,
      );
      expect(find.text('raw backend details'), findsNothing);

      auth.signInError = null;
      auth.signupError = Exception('password should never be shown');
      await switchToSignUp(tester);
      await enterValidSignup(tester);
      await tapButton(tester, 'Create Account');
      expect(
        find.text('We could not create your account. Please try again.'),
        findsOneWidget,
      );
      expect(
        find.textContaining('password should never be shown'),
        findsNothing,
      );
    });

    testWidgets('submission disables the action and prevents duplicates', (
      tester,
    ) async {
      final completer = Completer<AuthSignUpResult>();
      auth.signupCompleter = completer;
      await tester.pumpWidget(buildTestWidget());
      await switchToSignUp(tester);
      await enterValidSignup(tester);

      final button = find.widgetWithText(MitzoneButton, 'Create Account');
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pump();
      await tester.tap(find.byType(MitzoneButton));
      await tester.pump();
      expect(auth.signUpCalls, 1);

      completer.complete(auth.signupResult);
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });
}

class FakeAuthRepository implements AuthRepository {
  AuthSession? session;
  final _changes = StreamController<AuthSession?>.broadcast();
  Future<void> dispose() => _changes.close();
  AuthSignUpResult signupResult = const AuthSignUpResult(
    user: AuthUser(id: 'user-1', email: 'new@example.com'),
    session: AuthSession(
      user: AuthUser(id: 'user-1', email: 'new@example.com'),
    ),
    outcome: AuthSignUpOutcome.signedIn,
  );
  Completer<AuthSignUpResult>? signupCompleter;
  int signUpCalls = 0;
  String? signInEmail;
  Object? signInError;
  Object? signupError;

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
  Future<AuthSession?> restoreSession() async => session;

  @override
  Future<AuthSession> signIn({
    required String email,
    required String password,
  }) async {
    signInEmail = email;
    if (signInError != null) throw signInError!;
    session = const AuthSession(
      user: AuthUser(id: 'user-1', email: 'user@example.com'),
    );
    _changes.add(session);
    return session!;
  }

  @override
  Future<AuthSignUpResult> signUp({
    required String email,
    required String password,
  }) async {
    signUpCalls++;
    if (signupError != null) throw signupError!;
    final result =
        await (signupCompleter?.future ?? Future.value(signupResult));
    session = result.session;
    if (session != null) _changes.add(session);
    return result;
  }

  @override
  Future<void> signOut() async {
    session = null;
    _changes.add(null);
  }

  @override
  Stream<AuthSession?> get sessionChanges => _changes.stream;
}

class FakeProfileRepository implements ProfileRepository {
  UserProfile? profile;
  String? requestedId;

  @override
  Future<UserProfile?> getProfile(String identityId) async {
    requestedId = identityId;
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
  Future<UserProfile> saveProfile(UserProfile profile) async => profile;
}

class _CompletedOnboardingStore implements OnboardingStatusStore {
  @override
  Future<bool> isCompleted() async => true;
  @override
  Future<void> markCompleted() async {}
}
