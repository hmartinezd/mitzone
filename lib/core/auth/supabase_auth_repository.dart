import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_models.dart';
import 'auth_repository.dart';
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this.client);
  final SupabaseClient client;
  AuthSession? _map(Session? session) => session == null ? null : AuthSession(user: AuthUser(id: session.user.id, email: session.user.email));
  @override Future<AuthSession?> restoreSession() async => _map(client.auth.currentSession);
  @override Future<AuthSession> signIn({required String email, required String password}) async => _map((await client.auth.signInWithPassword(email: email, password: password)).session)!;
  @override Future<void> signOut() => client.auth.signOut();
  @override Stream<AuthSession?> get sessionChanges => client.auth.onAuthStateChange.map((event) => _map(event.session));
}
