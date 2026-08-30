import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/identity/identity_providers.dart';
import '../../../core/storage/storage_providers.dart';
import '../domain/connection.dart';
import '../domain/connection_repository.dart';
import '../domain/connection_request.dart';
import 'local_connection_repository.dart';
import '../../encounters/data/encounter_providers.dart';
import '../../encounters/domain/encounter.dart';
import '../../notifications/data/notification_providers.dart';
import '../../notifications/domain/local_notification.dart';

final connectionRepositoryProvider = Provider<ConnectionRepository>(
  (ref) => LocalConnectionRepository(ref.watch(localStorageProvider)),
);
final incomingConnectionRequestsProvider =
    FutureProvider<List<ConnectionRequest>>((ref) {
      final id = ref.watch(mockIdentityRepositoryProvider).currentUser.id;
      return ref.watch(connectionRepositoryProvider).getIncomingRequests(id);
    });
final outgoingConnectionRequestsProvider =
    FutureProvider<List<ConnectionRequest>>((ref) {
      final id = ref.watch(mockIdentityRepositoryProvider).currentUser.id;
      return ref.watch(connectionRepositoryProvider).getOutgoingRequests(id);
    });
final connectionsProvider = FutureProvider<List<Connection>>((ref) {
  final id = ref.watch(mockIdentityRepositoryProvider).currentUser.id;
  return ref.watch(connectionRepositoryProvider).getConnections(id);
});
final relationshipProvider =
    FutureProvider.family<RelationshipState, Encounter>((ref, encounter) {
      final current = ref.watch(mockIdentityRepositoryProvider).currentUser.id;
      final pair = [current, encounter.otherUserId]..sort();
      return ref
          .watch(connectionRepositoryProvider)
          .getRelationshipState(
            userAId: current,
            userBId: encounter.otherUserId,
            encounterId: encounter.id,
            contextId: '${encounter.eventId}:${pair.join(':')}',
          );
    });
final connectionControllerProvider = Provider(
  (ref) => ConnectionController(ref),
);

class ConnectionController {
  ConnectionController(this.ref);
  final Ref ref;
  Future<ConnectionRequest> send(String recipient, String encounter) async {
    final sender = ref.read(mockIdentityRepositoryProvider).currentUser.id;
    final valid = (await ref.read(encountersForCurrentUserProvider.future)).any(
      (item) =>
          item.id == encounter &&
          item.currentUserId == sender &&
          item.otherUserId == recipient,
    );
    if (!valid) throw StateError('Connection requires a valid encounter');
    final encounterData = (await ref.read(
      encountersForCurrentUserProvider.future,
    )).firstWhere((item) => item.id == encounter);
    final pair = [sender, recipient]..sort();
    final request = await ref
        .read(connectionRepositoryProvider)
        .sendRequest(
          senderUserId: sender,
          recipientUserId: recipient,
          encounterId: encounter,
          contextId: '${encounterData.eventId}:${pair.join(':')}',
        );
    await ref
        .read(notificationRepositoryProvider)
        .add(
          LocalNotification(
            id: 'request_${request.id}',
            type: LocalNotificationType.connectionRequest,
            userId: recipient,
            timestamp: request.createdAt,
            entityId: request.id,
            destination: '/app/matches',
          ),
        );
    return _refresh(request);
  }

  Future<ConnectionRequest> accept(String id) async {
    final result = await ref
        .read(connectionRepositoryProvider)
        .acceptRequest(
          requestId: id,
          recipientUserId: ref
              .read(mockIdentityRepositoryProvider)
              .currentUser
              .id,
        );
    await ref
        .read(notificationRepositoryProvider)
        .add(
          LocalNotification(
            id: 'accepted_$id',
            type: LocalNotificationType.connectionAccepted,
            userId: result.senderUserId,
            timestamp: result.createdAt,
            entityId: id,
            destination: '/app/chat',
          ),
        );
    return _refresh(result);
  }

  Future<ConnectionRequest> decline(String id) async => _refresh(
    await ref
        .read(connectionRepositoryProvider)
        .declineRequest(
          requestId: id,
          recipientUserId: ref
              .read(mockIdentityRepositoryProvider)
              .currentUser
              .id,
        ),
  );
  Future<ConnectionRequest> _refresh(ConnectionRequest value) async {
    ref.invalidate(incomingConnectionRequestsProvider);
    ref.invalidate(outgoingConnectionRequestsProvider);
    ref.invalidate(connectionsProvider);
    ref.invalidate(relationshipProvider);
    return value;
  }
}
