import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/identity/identity_providers.dart';
import '../../../core/storage/storage_providers.dart';
import '../../connections/data/connection_providers.dart';
import '../domain/chat_models.dart';
import '../domain/chat_repository.dart';
import 'local_chat_repository.dart';
import '../../encounters/data/encounter_providers.dart';
import '../../events/data/event_providers.dart';
import '../../notifications/data/notification_providers.dart';
import '../../../core/auth/auth_providers.dart';
import 'supabase_chat_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/identity/current_user_provider.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) => ref.watch(productionModeProvider)
  ? SupabaseChatRepository(Supabase.instance.client)
  : LocalChatRepository(
    ref.watch(localStorageProvider),
    ref.watch(connectionRepositoryProvider),
    notifications: ref.watch(notificationRepositoryProvider),
  ));

final chatConversationsProvider = FutureProvider<List<Conversation>>(
  (ref) async => ref
      .watch(chatRepositoryProvider)
      .getConversations(
        ref.watch(productionModeProvider) ? await ref.watch(currentUserIdProvider.future) : ref.watch(mockIdentityRepositoryProvider).currentUser.id,
      ),
);

final chatMessagesProvider = FutureProvider.family<List<Message>, String>((
  ref,
  id,
) async {
  // An open conversation must be re-authorized when its connection changes.
  ref.watch(connectionsProvider);
  return ref
      .watch(chatRepositoryProvider)
      .getMessages(
        conversationId: id,
        userId: ref.watch(productionModeProvider) ? await ref.watch(currentUserIdProvider.future) : ref.watch(mockIdentityRepositoryProvider).currentUser.id,
      );
});

final conversationContextProvider = FutureProvider.family<String?, String>((
  ref,
  id,
) async {
  final me = ref.watch(mockIdentityRepositoryProvider).currentUser.id;
  final conversation = (await ref.watch(
    chatConversationsProvider.future,
  )).where((c) => c.id == id).firstOrNull;
  if (conversation == null) return null;
  final connection = (await ref.watch(
    connectionsProvider.future,
  )).where((c) => c.id == conversation.connectionId).firstOrNull;
  if (connection == null) return null;
  final encounter = (await ref.watch(encountersForCurrentUserProvider.future))
      .where(
        (e) =>
            e.id == connection.encounterId &&
            (e.currentUserId == me || e.otherUserId == me),
      )
      .firstOrNull;
  final eventId = connection.contextId?.split(':').first;
  final resolvedEventId = eventId ?? encounter?.eventId;
  if (resolvedEventId == null) return null;
  final event = ref.watch(eventCatalogProvider).getById(resolvedEventId);
  return event == null ? null : 'You crossed paths at ${event.title}';
});
