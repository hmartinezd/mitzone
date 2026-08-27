import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/identity/mock_identity_repository.dart';
import '../../../core/storage/storage_providers.dart';
import '../domain/connection.dart';
import '../domain/connection_repository.dart';
import '../domain/connection_request.dart';
import 'local_connection_repository.dart';

final connectionRepositoryProvider = Provider<ConnectionRepository>((ref) => LocalConnectionRepository(ref.watch(localStorageProvider)));
final incomingConnectionRequestsProvider = FutureProvider<List<ConnectionRequest>>((ref) {
  final id = ref.watch(mockIdentityRepositoryProvider).currentUser.id;
  return ref.watch(connectionRepositoryProvider).getIncomingRequests(id);
});
final outgoingConnectionRequestsProvider = FutureProvider<List<ConnectionRequest>>((ref) {
  final id = ref.watch(mockIdentityRepositoryProvider).currentUser.id;
  return ref.watch(connectionRepositoryProvider).getOutgoingRequests(id);
});
final connectionsProvider = FutureProvider<List<Connection>>((ref) {
  final id = ref.watch(mockIdentityRepositoryProvider).currentUser.id;
  return ref.watch(connectionRepositoryProvider).getConnections(id);
});
final connectionControllerProvider = Provider((ref) => ConnectionController(ref));

class ConnectionController {
  ConnectionController(this.ref);
  final Ref ref;
  Future<ConnectionRequest> send(String recipient, String encounter) async => _refresh(await ref.read(connectionRepositoryProvider).sendRequest(senderUserId: ref.read(mockIdentityRepositoryProvider).currentUser.id, recipientUserId: recipient, encounterId: encounter));
  Future<ConnectionRequest> accept(String id) async => _refresh(await ref.read(connectionRepositoryProvider).acceptRequest(requestId: id, recipientUserId: ref.read(mockIdentityRepositoryProvider).currentUser.id));
  Future<ConnectionRequest> decline(String id) async => _refresh(await ref.read(connectionRepositoryProvider).declineRequest(requestId: id, recipientUserId: ref.read(mockIdentityRepositoryProvider).currentUser.id));
  Future<ConnectionRequest> _refresh(ConnectionRequest value) async { ref.invalidate(incomingConnectionRequestsProvider); ref.invalidate(outgoingConnectionRequestsProvider); ref.invalidate(connectionsProvider); return value; }
}
