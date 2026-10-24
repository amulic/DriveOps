import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driveops_management/services/chat_api_service.dart';
import 'package:driveops_management/shared/models/chat_message.dart';

/// Message history for a conversation. The server returns page 1 newest-first
/// (descending), which is exactly the order the thread screen expects
/// (index 0 = newest, rendered at the bottom via `reverse: true`).
/// autoDispose so re-entering a thread always refetches fresh history.
final messagesProvider = FutureProvider.autoDispose
    .family<List<ChatMessage>, String>((ref, conversationId) async {
  final chatApi = ref.watch(chatApiServiceProvider);
  final paged = await chatApi.getMessages(conversationId, page: 1, pageSize: 100);
  return paged.messages;
});
