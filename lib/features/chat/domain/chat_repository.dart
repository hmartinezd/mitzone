import 'chat_models.dart';

abstract interface class ChatRepository {
  Future<List<Conversation>> getConversations(String userId);
  Future<Conversation> getOrCreateConversation({
    required String connectionId,
    required String userId,
  });
  Future<List<Message>> getMessages(String conversationId);
  Future<Message> sendMessage({
    required String conversationId,
    required String senderUserId,
    required String text,
  });
}
