import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_models.dart';
import 'auth_repository.dart';
import '../errors/domain_error.dart';

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this.client);
  final SupabaseClient client;
  AuthSession? _map(Session? session) => session == null
      ? null
      : AuthSession(
          user: AuthUser(id: session.user.id, email: session.user.email),
        );
  @override
  Future<AuthSession?> restoreSession() async =>
      _map(client.auth.currentSession);
  @override
  Future<AuthSession> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final session = _map(
        (await client.auth.signInWithPassword(
          email: email,
          password: password,
        )).session,
      );
      if (session == null) {
        throw const DomainError(
          DomainErrorCode.unauthorized,
          'Authentication did not return a session',
        );
      }
      return session;
    } on DomainError {
      rethrow;
    } catch (_) {
      throw const DomainError(
        DomainErrorCode.unauthorized,
        'Authentication failed',
      );
    }
  }

  @override
  Future<void> signOut() => client.auth.signOut();
  @override
  Stream<AuthSession?> get sessionChanges =>
      client.auth.onAuthStateChange.map((event) => _map(event.session));
}
