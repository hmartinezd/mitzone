import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'identity_gateway.dart';
import 'mock_identity_repository.dart';
import '../auth/auth_providers.dart';
import 'authenticated_identity_gateway.dart';

/// Provider for the [IdentityGateway].
final identityGatewayProvider = Provider<IdentityGateway>((ref) {
  if (ref.watch(productionModeProvider)) {
    return AuthenticatedIdentityGateway(ref.watch(authSessionProvider));
  }
  return MockIdentityGateway(ref.watch(mockIdentityRepositoryProvider));
});

final mockIdentityRepositoryProvider =
    ChangeNotifierProvider<InMemoryMockIdentityRepository>((ref) {
      return InMemoryMockIdentityRepository();
    });
