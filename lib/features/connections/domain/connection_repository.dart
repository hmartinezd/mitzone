import 'connection.dart';
import 'connection_request.dart';

enum RelationshipState {
  none,
  outgoingPending,
  incomingPending,
  connected,
  declined,
}

abstract interface class ConnectionRepository {
  Future<ConnectionRequest?> getRelationship({
    required String userAId,
    required String userBId,
    required String encounterId,
    String? contextId,
  });
  Future<ConnectionRequest> sendRequest({
    required String senderUserId,
    required String recipientUserId,
    required String encounterId,
    String? contextId,
  });
  Future<List<ConnectionRequest>> getIncomingRequests(String userId);
  Future<List<ConnectionRequest>> getOutgoingRequests(String userId);
  Future<ConnectionRequest> acceptRequest({
    required String requestId,
    required String recipientUserId,
  });
  Future<ConnectionRequest> declineRequest({
    required String requestId,
    required String recipientUserId,
  });
  Future<List<Connection>> getConnections(String userId);
  Future<void> removeConnection({
    required String connectionId,
    required String userId,
  });
  Future<RelationshipState> getRelationshipState({
    required String userAId,
    required String userBId,
    String? contextId,
    String? encounterId,
  });
}
