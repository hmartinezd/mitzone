import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mitzone/app/theme/app_theme.dart';
import 'package:mitzone/core/auth/auth_models.dart';
import 'package:mitzone/core/auth/auth_providers.dart';
import 'package:mitzone/core/auth/auth_repository.dart';
import 'package:mitzone/core/errors/domain_error.dart';
import 'package:mitzone/features/auth/presentation/login_screen.dart';
import 'package:mitzone/features/profile/data/profile_providers.dart';
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

    Widget buildTestWidget() {
      final router = GoRouter(
        initialLocation: '/login',
        routes: [
          GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
          GoRoute(
            path: '/profile/create',
            builder: (_, _) => const Text('create-profile-route'),
          ),
          GoRoute(
            path: '/app/home',
            builder: (_, _) => const Text('home-route'),
          ),
        ],
      );
      return ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          profileRepositoryProvider.overrideWithValue(profiles),
        ],
        child: MaterialApp.router(
          theme: AppTheme.darkTheme,
          routerConfig: router,
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
        expect(find.text('create-profile-route'), findsNothing);
        expect(auth.signUpCalls, 1);

        await tapButton(tester, 'Back to Sign In');
        await tester.pumpAndSettle();
        expect(find.text('Welcome back'), findsOneWidget);
        expect(find.byType(TextFormField), findsNWidgets(2));
        expect(find.text('new@example.com'), findsOneWidget);
      },
    );

    testWidgets('immediate signup routes to minimum profile when missing', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await switchToSignUp(tester);
      await enterValidSignup(tester);

      await tapButton(tester, 'Create Account');
      await tester.pumpAndSettle();

      expect(find.text('create-profile-route'), findsOneWidget);
      expect(profiles.requestedId, 'user-1');
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

      expect(find.text('home-route'), findsOneWidget);
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
      expect(find.text('create-profile-route'), findsOneWidget);
    });
  });
}

class FakeAuthRepository implements AuthRepository {
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

  @override
  Future<AuthSession?> restoreSession() async => null;

  @override
  Future<AuthSession> signIn({
    required String email,
    required String password,
  }) async {
    signInEmail = email;
    if (signInError != null) throw signInError!;
    return const AuthSession(
      user: AuthUser(id: 'user-1', email: 'user@example.com'),
    );
  }

  @override
  Future<AuthSignUpResult> signUp({
    required String email,
    required String password,
  }) {
    signUpCalls++;
    if (signupError != null) return Future.error(signupError!);
    return signupCompleter?.future ?? Future.value(signupResult);
  }

  @override
  Future<void> signOut() async {}

  @override
  Stream<AuthSession?> get sessionChanges => const Stream.empty();
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
  }) async => UserProfile(
    id: identityId,
    displayName: displayName,
    avatarUri: avatarUri,
  );

  @override
  Future<UserProfile> saveProfile(UserProfile profile) async => profile;
}
