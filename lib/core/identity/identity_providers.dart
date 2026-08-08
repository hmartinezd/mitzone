import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/storage_providers.dart';
import 'identity_gateway.dart';
import 'local_identity_gateway.dart';

/// Provider for the [IdentityGateway].
final identityGatewayProvider = Provider<IdentityGateway>((ref) {
  final storage = ref.watch(localStorageProvider);
  return LocalIdentityGateway(storage);
});
