import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_identity.dart';
import 'identity_gateway.dart';

/// Identity adapter backed exclusively by the authenticated Supabase session.
class AuthenticatedIdentityGateway implements IdentityGateway {
  const AuthenticatedIdentityGateway(this._session);
  final AsyncValue<dynamic> _session;

  AppIdentity? _current() {
    final user = _session.value?.user;
    return user == null
        ? null
        : AppIdentity(id: user.id as String, type: AppIdentityType.authenticated);
  }

  @override
  Future<AppIdentity> ensureIdentity() async {
    final identity = _current();
    if (identity == null) throw StateError('Authentication required');
    return identity;
  }

  @override
  Future<AppIdentity?> getExistingIdentity() async => _current();
}
