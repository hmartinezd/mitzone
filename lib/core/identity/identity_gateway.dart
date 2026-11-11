import 'app_identity.dart';

/// Interface for managing the application's user identity.
abstract interface class IdentityGateway {
  /// Ensures a valid user identity exists.
  ///
  /// If no identity is found, a new one is generated and persisted.
  Future<AppIdentity> ensureIdentity();

  /// Returns the current user identity if it exists, otherwise null.
  Future<AppIdentity?> getExistingIdentity();
}
