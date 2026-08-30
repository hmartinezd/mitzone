class AuthUser { const AuthUser({required this.id, this.email}); final String id; final String? email; }
class AuthSession { const AuthSession({required this.user}); final AuthUser user; }
