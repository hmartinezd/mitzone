/// Recovery authorization is granted only by a validated Supabase PKCE exchange.
/// It is deliberately not restored from an ordinary persisted sign-in session.
enum PasswordRecoveryState {
  idle,
  validating,
  ready,
  invalid,
  expired,
  completed;

  bool get blocksApp => this != idle;
}

abstract interface class PasswordRecoveryRepository {
  Stream<PasswordRecoveryState> get passwordRecoveryStates;
}

const passwordRecoveryRedirect = 'mitzone://auth/reset-password';
