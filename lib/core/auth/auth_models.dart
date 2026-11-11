class AuthUser {
  const AuthUser({required this.id, this.email, this.metadata = const {}});
  final String id;
  final String? email;
  final Map<String, dynamic> metadata;
}

class AuthSession {
  const AuthSession({required this.user});
  final AuthUser user;
}

/// The result of creating an email/password account.
///
/// Supabase can create the user without creating a session when email
/// confirmation is enabled. Keeping that outcome explicit prevents callers
/// from treating an unconfirmed account as authenticated.
enum AuthSignUpOutcome { signedIn, confirmationRequired }

class AuthSignUpResult {
  const AuthSignUpResult({
    required this.user,
    required this.outcome,
    this.session,
  });

  final AuthUser user;
  final AuthSignUpOutcome outcome;
  final AuthSession? session;

  bool get isSignedIn => outcome == AuthSignUpOutcome.signedIn;
}
