class Conversation {
  const Conversation({
    required this.id,
    required this.connectionId,
    required this.userAId,
    required this.userBId,
    required this.createdAt,
    this.lastMessageAt,
  });
  final String id, connectionId, userAId, userBId;
  final DateTime createdAt;
  final DateTime? lastMessageAt;
}

class Message {
  const Message({
    required this.id,
    required this.conversationId,
    required this.senderUserId,
    required this.text,
    required this.sentAt,
  });
  final String id, conversationId, senderUserId, text;
  final DateTime sentAt;
}
