import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driveops_management/services/chat_api_service.dart';
import 'package:driveops_management/shared/models/conversation_summary.dart';
import 'package:driveops_management/shared/models/conversation.dart';
import 'package:driveops_management/features/messages/presentation/providers/chat_signalr_provider.dart';

final conversationsProvider = AsyncNotifierProvider<ConversationsNotifier, List<ConversationSummary>>(ConversationsNotifier.new);

class ConversationsNotifier extends AsyncNotifier<List<ConversationSummary>> {
  @override
  Future<List<ConversationSummary>> build() async {
    final chatApi = ref.watch(chatApiServiceProvider);
    ref.watch(chatSignalrConnectionProvider);

    final chatSignalr = ref.watch(chatSignalrServiceProvider);
    chatSignalr.on('ConversationUpdated', (_) {
      ref.invalidateSelf();
    });

    ref.onDispose(() {
      chatSignalr.off('ConversationUpdated');
    });

    return chatApi.getMyConversations();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }

  Future<Conversation> createDirectConversation(String otherUserId) async {
    final chatApi = ref.read(chatApiServiceProvider);
    final conversation = await chatApi.createDirectConversation(otherUserId);
    ref.invalidateSelf();
    return conversation;
  }

  Future<Conversation> joinTripConversation(String conversationId) async {
    final chatApi = ref.read(chatApiServiceProvider);
    final conversation = await chatApi.joinConversation(conversationId);
    ref.invalidateSelf();
    return conversation;
  }
}