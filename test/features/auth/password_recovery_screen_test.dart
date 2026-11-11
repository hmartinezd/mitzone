import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitzone/app/router/app_router.dart';
import 'package:mitzone/app/router/app_routes.dart';
import 'package:mitzone/app/theme/app_theme.dart';
import 'package:mitzone/core/auth/auth_models.dart';
import 'package:mitzone/core/auth/auth_providers.dart';
import 'package:mitzone/core/auth/auth_repository.dart';
import 'package:mitzone/core/auth/password_recovery.dart';
import 'package:mitzone/core/errors/domain_error.dart';
import 'package:mitzone/features/auth/presentation/forgot_password_screen.dart';
import 'package:mitzone/features/auth/presentation/login_screen.dart';
import 'package:mitzone/features/auth/presentation/reset_password_screen.dart';
import 'package:mitzone/shared/widgets/mitzone_button.dart';

void main() {
  late _RecoveryAuth auth;
  setUp(() => auth = _RecoveryAuth());
  tearDown(() => auth.dispose());

  Widget app({String location = AppRoutes.forgotPassword, double scale = 1}) =>
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          routerInitialLocationProvider.overrideWithValue(location),
        ],
        child: Consumer(
          builder: (context, ref, _) => MaterialApp.router(
            theme: AppTheme.darkTheme,
            routerConfig: ref.watch(routerProvider),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
          ),
        ),
      );

  Future<void> tap(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text));
    await tester.tap(find.text(text));
    await tester.pump();
  }

  Future<void> enterPasswords(
    WidgetTester tester, {
    String confirmation = 'new-test-password',
  }) async {
    await tester.enterText(
      find.byKey(const ValueKey('recovery-password')),
      'new-test-password',
    );
    await tester.enterText(
      find.byKey(const ValueKey('recovery-confirmation')),
      confirmation,
    );
  }

  testWidgets(
    'Forgot password opens a separate form and preserves typed email',
    (tester) async {
      await tester.pumpWidget(app(location: AppRoutes.login));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('auth-email')),
        'person@example.com',
      );
      await tap(tester, 'Forgot password?');
      await tester.pumpAndSettle();
      expect(find.byType(ForgotPasswordScreen), findsOneWidget);
      expect(find.text('person@example.com'), findsOneWidget);
      expect(auth.requests, isEmpty);
    },
  );

  testWidgets('invalid email does not invoke recovery', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('recovery-email')),
      'invalid',
    );
    await tap(tester, 'Send recovery email');
    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(auth.requests, isEmpty);
  });

  testWidgets(
    'request is serialized while loading and acknowledgement does not enumerate accounts',
    (tester) async {
      auth.requestCompletion = Completer<void>();
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('recovery-email')),
        ' person@example.com ',
      );
      await tap(tester, 'Send recovery email');
      final button = tester.widget<MitzoneButton>(find.byType(MitzoneButton));
      expect(button.isLoading, isTrue);
      expect(button.onPressed, isNull);
      expect(auth.requests, ['person@example.com']);
      auth.requestCompletion!.complete();
      await tester.pumpAndSettle();
      expect(find.text('Check your email'), findsOneWidget);
      expect(
        find.textContaining('If an account exists for this email'),
        findsOneWidget,
      );
      expect(find.text('Send another email'), findsOneWidget);
    },
  );

  testWidgets('request errors never expose raw exceptions', (tester) async {
    auth.requestError = StateError('private account details');
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('recovery-email')),
      'person@example.com',
    );
    await tap(tester, 'Send recovery email');
    await tester.pumpAndSettle();
    expect(
      find.text(
        'We could not send recovery instructions. Please try again later.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('private account details'), findsNothing);
    expect(find.text('Check your email'), findsNothing);
  });

  testWidgets('ordinary signed-in session cannot see the reset form', (
    tester,
  ) async {
    auth.session = const AuthSession(user: AuthUser(id: 'normal-user'));
    await tester.pumpWidget(app(location: AppRoutes.resetPassword));
    await tester.pumpAndSettle();
    expect(find.text('Invalid recovery link'), findsOneWidget);
    expect(find.byKey(const ValueKey('recovery-password')), findsNothing);
    expect(auth.updates, isEmpty);
  });

  testWidgets('validation is explicit and does not expose a form prematurely', (
    tester,
  ) async {
    auth.state = PasswordRecoveryState.validating;
    await tester.pumpWidget(app(location: AppRoutes.resetPassword));
    await tester.pump();
    expect(find.text('Checking recovery link'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byKey(const ValueKey('recovery-password')), findsNothing);
    auth.emit(PasswordRecoveryState.ready);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('recovery-password')), findsOneWidget);
  });

  testWidgets('expired and invalid links offer a fresh request', (
    tester,
  ) async {
    auth.state = PasswordRecoveryState.expired;
    await tester.pumpWidget(app(location: AppRoutes.resetPassword));
    await tester.pumpAndSettle();
    expect(find.text('Recovery link expired'), findsOneWidget);
    expect(find.byKey(const ValueKey('recovery-password')), findsNothing);
    auth.emit(PasswordRecoveryState.invalid);
    await tester.pumpAndSettle();
    expect(find.text('Invalid recovery link'), findsOneWidget);
    await tap(tester, 'Request a new link');
    await tester.pumpAndSettle();
    expect(find.byType(ForgotPasswordScreen), findsOneWidget);
  });

  testWidgets('confirmation mismatch prevents mutation', (tester) async {
    auth.state = PasswordRecoveryState.ready;
    await tester.pumpWidget(app(location: AppRoutes.resetPassword));
    await tester.pumpAndSettle();
    await enterPasswords(tester, confirmation: 'different');
    await tap(tester, 'Update password');
    expect(find.text('Passwords do not match.'), findsOneWidget);
    expect(auth.updates, isEmpty);
  });

  testWidgets(
    'validated reset updates once, clears password fields and returns to sign in',
    (tester) async {
      auth.state = PasswordRecoveryState.ready;
      auth.session = const AuthSession(user: AuthUser(id: 'recovery-user'));
      auth.updateCompletion = Completer<void>();
      await tester.pumpWidget(app(location: AppRoutes.resetPassword));
      await tester.pumpAndSettle();
      await enterPasswords(tester);
      await tap(tester, 'Update password');
      expect(auth.updates, ['new-test-password']);
      expect(
        tester.widget<MitzoneButton>(find.byType(MitzoneButton)).isLoading,
        isTrue,
      );
      auth.updateCompletion!.complete();
      await tester.pumpAndSettle();
      expect(find.text('Password updated'), findsOneWidget);
      expect(find.byKey(const ValueKey('recovery-password')), findsNothing);
      await tap(tester, 'Back to Sign In');
      await tester.pumpAndSettle();
      expect(auth.signOutCount, 1);
      expect(auth.session, isNull);
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(ResetPasswordScreen), findsNothing);
    },
  );

  testWidgets('safe password policy error permits correcting and retrying', (
    tester,
  ) async {
    auth.state = PasswordRecoveryState.ready;
    auth.updateError = const DomainError(
      DomainErrorCode.validation,
      'Choose a stronger password.',
    );
    await tester.pumpWidget(app(location: AppRoutes.resetPassword));
    await tester.pumpAndSettle();
    await enterPasswords(tester);
    await tap(tester, 'Update password');
    await tester.pumpAndSettle();
    expect(find.text('Choose a stronger password.'), findsOneWidget);
    expect(find.byKey(const ValueKey('recovery-password')), findsOneWidget);
    auth.updateError = null;
    await tap(tester, 'Update password');
    await tester.pumpAndSettle();
    expect(find.text('Password updated'), findsOneWidget);
  });

  testWidgets(
    'session invalidation clears sensitive input and disables mutation',
    (tester) async {
      auth.state = PasswordRecoveryState.ready;
      await tester.pumpWidget(app(location: AppRoutes.resetPassword));
      await tester.pumpAndSettle();
      await enterPasswords(tester);
      auth.emit(PasswordRecoveryState.expired);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('recovery-password')), findsNothing);
      auth.emit(PasswordRecoveryState.ready);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).first)
            .controller!
            .text,
        isEmpty,
      );
      await tap(tester, 'Update password');
      expect(auth.updates, isEmpty);
    },
  );

  testWidgets(
    'recovery and completion prevent navigation to protected content',
    (tester) async {
      auth.state = PasswordRecoveryState.ready;
      auth.session = const AuthSession(user: AuthUser(id: 'recovery-user'));
      await tester.pumpWidget(app(location: AppRoutes.resetPassword));
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(ResetPasswordScreen)),
      );
      final router = container.read(routerProvider);
      for (final state in [
        PasswordRecoveryState.ready,
        PasswordRecoveryState.completed,
        PasswordRecoveryState.expired,
      ]) {
        auth.emit(state);
        await tester.pumpAndSettle();
        router.go(AppRoutes.profile);
        await tester.pumpAndSettle();
        expect(
          router.routeInformationProvider.value.uri.path,
          AppRoutes.resetPassword,
        );
        expect(find.byType(ResetPasswordScreen), findsOneWidget);
      }
    },
  );

  testWidgets('request and reset remain usable at 320x480 with 2x text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(app(scale: 2));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('recovery-email')),
      'person@example.com',
    );
    await tap(tester, 'Send recovery email');
    await tester.pumpAndSettle();
    expect(find.text('Check your email'), findsOneWidget);
    expect(tester.takeException(), isNull);
    auth.emit(PasswordRecoveryState.ready);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(ForgotPasswordScreen)),
    );
    container.read(routerProvider).go(AppRoutes.resetPassword);
    await tester.pumpAndSettle();
    await enterPasswords(tester);
    await tap(tester, 'Update password');
    await tester.pumpAndSettle();
    expect(find.text('Password updated'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _RecoveryAuth implements AuthRepository, PasswordRecoveryRepository {
  PasswordRecoveryState state = PasswordRecoveryState.idle;
  AuthSession? session;
  final _states = StreamController<PasswordRecoveryState>.broadcast();
  final _sessions = StreamController<AuthSession?>.broadcast();
  final requests = <String>[];
  final updates = <String>[];
  int signOutCount = 0;
  Completer<void>? requestCompletion;
  Completer<void>? updateCompletion;
  Object? requestError;
  Object? updateError;

  void emit(PasswordRecoveryState next) {
    state = next;
    _states.add(next);
  }

  @override
  Stream<PasswordRecoveryState> get passwordRecoveryStates =>
      Stream.multi((sink) {
        final sub = _states.stream.listen(sink.add);
        sink.add(state);
        sink.onCancel = sub.cancel;
      });
  @override
  Stream<bool> get recoveryEvents => passwordRecoveryStates.map(
    (state) => state == PasswordRecoveryState.ready,
  );
  @override
  Stream<AuthSession?> get sessionChanges => _sessions.stream;
  @override
  Future<AuthSession?> restoreSession() async => session;
  @override
  Future<void> requestPasswordReset(String email) async {
    requests.add(email);
    if (requestError != null) throw requestError!;
    await requestCompletion?.future;
  }

  @override
  Future<void> updatePassword(String password) async {
    updates.add(password);
    if (updateError != null) throw updateError!;
    await updateCompletion?.future;
    emit(PasswordRecoveryState.completed);
  }

  @override
  Future<void> signOut() async {
    signOutCount++;
    session = null;
    _sessions.add(null);
    emit(PasswordRecoveryState.idle);
  }

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
  Future<void> deleteAccount() => throw UnimplementedError();
  Future<void> dispose() async {
    await _states.close();
    await _sessions.close();
  }
}
