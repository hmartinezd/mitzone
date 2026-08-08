/// The type of identity associated with the application.
enum AppIdentityType {
  /// A stable, locally generated identity for development use.
  localDevelopment,

  /// A permanent, verified identity authenticated against a backend.
  authenticated,
}

/// Represents the identity of the current application user.
class AppIdentity {
  const AppIdentity({required this.id, required this.type});

  /// The unique identifier for this user.
  final String id;

  /// The category of this identity.
  final AppIdentityType type;
}
