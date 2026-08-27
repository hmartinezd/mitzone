import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/identity/mock_identity_repository.dart';
import '../../../core/storage/storage_providers.dart';
import '../../connections/data/connection_providers.dart';
import '../domain/chat_repository.dart';
import 'local_chat_repository.dart';
final chatRepositoryProvider=Provider<ChatRepository>((ref)=>LocalChatRepository(ref.watch(localStorageProvider),ref.watch(connectionRepositoryProvider)));
final chatConversationsProvider=FutureProvider((ref)=>ref.watch(chatRepositoryProvider).getConversations(ref.watch(mockIdentityRepositoryProvider).currentUser.id));
final chatMessagesProvider=FutureProvider.family((ref,String id)=>ref.watch(chatRepositoryProvider).getMessages(id));
