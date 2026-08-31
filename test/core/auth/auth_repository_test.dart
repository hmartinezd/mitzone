import 'package:flutter_test/flutter_test.dart';
import 'package:mitzone/core/auth/auth_models.dart';
import 'package:mitzone/core/auth/auth_repository.dart';

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
      await fake.signOut();
      expect(await fake.restoreSession(), isNull);
    },
  );
}

class FakeAuth implements AuthRepository {
  AuthSession? value = const AuthSession(user: AuthUser(id: 'user-1'));
  @override
  Future<AuthSession?> restoreSession() async => value;
  @override
  Future<AuthSession> signIn({
    required String email,
    required String password,
  }) async => value = AuthSession(
    user: AuthUser(id: 'user-1', email: email),
  );
  @override
  Future<void> signOut() async => value = null;
  @override
  Stream<AuthSession?> get sessionChanges => const Stream.empty();
}
