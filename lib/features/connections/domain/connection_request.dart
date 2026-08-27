enum ConnectionRequestStatus { pending, accepted, declined }

class ConnectionRequest {
  const ConnectionRequest({required this.id, required this.senderUserId, required this.recipientUserId, required this.encounterId, required this.createdAt, required this.status});
  final String id;
  final String senderUserId;
  final String recipientUserId;
  final String encounterId;
  final DateTime createdAt;
  final ConnectionRequestStatus status;
}
