import 'package:flutter_test/flutter_test.dart';
import 'package:mitzone/core/auth/auth_models.dart';
import 'package:mitzone/core/auth/auth_repository.dart';
import 'package:mitzone/core/errors/domain_error.dart';

void main() {
  test(
    'auth contract exposes backend-neutral identity and restoration',
    () async {
      final fake = FakeAuth();
      expect((await fake.restoreSession())?.user.id, 'user-1');
      final signed = await fake.signIn(
        email: 'a@example.com',
        password: 'secret',
      );
      expect(signed.user.email, 'a@example.com');
      final signup = await fake.signUp(
        email: 'new@example.com',
        password: 'secret',
      );
      expect(signup.isSignedIn, isTrue);
      await fake.signOut();
      expect(await fake.restoreSession(), isNull);
    },
  );

  test('signup contract represents confirmation-required accounts', () async {
    final fake = FakeAuth()
      ..signupResult = const AuthSignUpResult(
        user: AuthUser(id: 'user-2', email: 'confirm@example.com'),
        outcome: AuthSignUpOutcome.confirmationRequired,
      );

    final result = await fake.signUp(
      email: 'confirm@example.com',
      password: 'secret',
    );

    expect(result.outcome, AuthSignUpOutcome.confirmationRequired);
    expect(result.session, isNull);
    expect(result.user.id, 'user-2');
  });

  test('auth failures remain domain errors', () async {
    final fake = FakeAuth()
      ..signupFailure = const DomainError(
        DomainErrorCode.unauthorized,
        'safe auth failure',
      )
      ..signInFailure = const DomainError(
        DomainErrorCode.unauthorized,
        'safe auth failure',
      );

    expect(
      () => fake.signUp(email: 'a@example.com', password: 'secret'),
      throwsA(isA<DomainError>()),
    );
    expect(
      () => fake.signIn(email: 'a@example.com', password: 'secret'),
      throwsA(isA<DomainError>()),
    );
  });
}

class FakeAuth implements AuthRepository {
  AuthSession? value = const AuthSession(user: AuthUser(id: 'user-1'));
  AuthSignUpResult signupResult = const AuthSignUpResult(
    user: AuthUser(id: 'user-1', email: 'new@example.com'),
    session: AuthSession(
      user: AuthUser(id: 'user-1', email: 'new@example.com'),
    ),
    outcome: AuthSignUpOutcome.signedIn,
  );
  Object? signupFailure;
  Object? signInFailure;
  @override
  Future<AuthSession?> restoreSession() async => value;
  @override
  Future<AuthSession> signIn({
    required String email,
    required String password,
  }) async {
    if (signInFailure != null) throw signInFailure!;
    return value = AuthSession(
      user: AuthUser(id: 'user-1', email: email),
    );
  }

  @override
  Future<AuthSignUpResult> signUp({
    required String email,
    required String password,
  }) async {
    if (signupFailure != null) throw signupFailure!;
    return signupResult;
  }

  @override
  Future<void> signOut() async => value = null;
  @override
  Stream<AuthSession?> get sessionChanges => const Stream.empty();
}
