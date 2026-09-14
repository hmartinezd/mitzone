import 'auth_models.dart';

abstract interface class AuthRepository {
  Future<AuthSession?> restoreSession();
  Future<AuthSession> signIn({required String email, required String password});
  Future<AuthSignUpResult> signUp({
    required String email,
    required String password,
  });
  Future<void> signOut();
  Future<void> requestPasswordReset(String email) =>
      throw UnimplementedError('Password recovery is unavailable.');
  Future<void> updatePassword(String password) =>
      throw UnimplementedError('Password reset is unavailable.');
  Future<void> deleteAccount() =>
      throw UnimplementedError('Account deletion is unavailable.');
  Stream<AuthSession?> get sessionChanges;
  Stream<bool> get recoveryEvents => const Stream<bool>.empty();
}
