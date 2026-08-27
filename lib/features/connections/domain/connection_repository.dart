import 'connection.dart';
import 'connection_request.dart';

abstract interface class ConnectionRepository {
  Future<ConnectionRequest?> getRelationship({required String userAId, required String userBId, required String encounterId});
  Future<ConnectionRequest> sendRequest({required String senderUserId, required String recipientUserId, required String encounterId});
  Future<List<ConnectionRequest>> getIncomingRequests(String userId);
  Future<List<ConnectionRequest>> getOutgoingRequests(String userId);
  Future<ConnectionRequest> acceptRequest({required String requestId, required String recipientUserId});
  Future<ConnectionRequest> declineRequest({required String requestId, required String recipientUserId});
  Future<List<Connection>> getConnections(String userId);
}
