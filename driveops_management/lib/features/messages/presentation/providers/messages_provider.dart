import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driveops_management/services/chat_api_service.dart';
import 'package:driveops_management/shared/models/chat_message.dart';

final messagesProvider = FutureProvider.family<List<ChatMessage>, String>((ref, conversationId) async {
  final chatApi = ref.watch(chatApiServiceProvider);
  final paged = await chatApi.getMessages(conversationId, page: 1, pageSize: 100);
  return paged.messages.reversed.toList();
});