import 'auth_models.dart';
abstract interface class AuthRepository {
  Future<AuthSession?> restoreSession();
  Future<AuthSession> signIn({required String email, required String password});
  Future<void> signOut();
  Stream<AuthSession?> get sessionChanges;
}
