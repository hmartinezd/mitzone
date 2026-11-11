class Connection {
  const Connection({
    required this.id,
    required this.userAId,
    required this.userBId,
    required this.encounterId,
    required this.connectedAt,
    this.contextId,
  });
  final String id;
  final String userAId;
  final String userBId;
  final String encounterId;
  final DateTime connectedAt;
  final String? contextId;
}
