import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/identity/identity_providers.dart';
import '../../../core/storage/storage_providers.dart';
import '../../connections/data/connection_providers.dart';
import '../domain/chat_models.dart';
import '../domain/chat_repository.dart';
import 'local_chat_repository.dart';
import '../../encounters/data/encounter_providers.dart';
import '../../events/data/event_providers.dart';

final chatRepositoryProvider = Provider<ChatRepository>(
  (ref) => LocalChatRepository(
    ref.watch(localStorageProvider),
    ref.watch(connectionRepositoryProvider),
  ),
);

final chatConversationsProvider = FutureProvider<List<Conversation>>(
  (ref) => ref
      .watch(chatRepositoryProvider)
      .getConversations(
        ref.watch(mockIdentityRepositoryProvider).currentUser.id,
      ),
);

final chatMessagesProvider = FutureProvider.family<List<Message>, String>(
  (ref, id) => ref.watch(chatRepositoryProvider).getMessages(id),
);

final conversationContextProvider = FutureProvider.family<String?, String>((ref, id) async {
  final me = ref.watch(mockIdentityRepositoryProvider).currentUser.id;
  final conversation = (await ref.watch(chatConversationsProvider.future)).where((c) => c.id == id).firstOrNull;
  if (conversation == null) return null;
  final connection = (await ref.watch(connectionsProvider.future)).where((c) => c.id == conversation.connectionId).firstOrNull;
  if (connection == null) return null;
  final encounter = (await ref.watch(encountersForCurrentUserProvider.future)).where((e) => e.id == connection.encounterId && (e.currentUserId == me || e.otherUserId == me)).firstOrNull;
  final event = encounter == null ? null : ref.watch(encounterEventProvider(encounter.eventId));
  return event == null ? null : 'You crossed paths at ${event.title}';
});
