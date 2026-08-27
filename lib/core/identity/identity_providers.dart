import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'identity_gateway.dart';
import 'mock_identity_repository.dart';

/// Provider for the [IdentityGateway].
final identityGatewayProvider = Provider<IdentityGateway>((ref) {
  return MockIdentityGateway(ref.watch(mockIdentityRepositoryProvider));
});

final mockIdentityRepositoryProvider = ChangeNotifierProvider<InMemoryMockIdentityRepository>((ref) {
  return InMemoryMockIdentityRepository();
});
