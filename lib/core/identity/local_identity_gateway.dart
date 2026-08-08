import 'dart:async';
import 'package:uuid/uuid.dart';
import '../storage/local_storage.dart';
import 'app_identity.dart';
import 'identity_gateway.dart';

/// An implementation of [IdentityGateway] that manages a stable, local ID.
class LocalIdentityGateway implements IdentityGateway {
  LocalIdentityGateway(this._storage);

  final LocalStorage _storage;

  /// Versioned key for storing the local identity ID.
  static const String _key = 'local_identity.id.v1';

  /// Guard to prevent concurrent identity generation.
  Future<AppIdentity>? _inFlight;

  @override
  Future<AppIdentity?> getExistingIdentity() async {
    final id = await _storage.getString(_key);
    if (id == null) return null;
    return AppIdentity(id: id, type: AppIdentityType.localDevelopment);
  }

  @override
  Future<AppIdentity> ensureIdentity() async {
    final existing = await getExistingIdentity();
    if (existing != null) return existing;

    if (_inFlight != null) return _inFlight!;

    _inFlight = _generateAndPersist();
    try {
      return await _inFlight!;
    } finally {
      _inFlight = null;
    }
  }

  Future<AppIdentity> _generateAndPersist() async {
    final id = const Uuid().v4();
    await _storage.setString(_key, id);
    return AppIdentity(id: id, type: AppIdentityType.localDevelopment);
  }
}
