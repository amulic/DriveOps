import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driveops_mobile/services/chat_api_service.dart';
import 'package:driveops_mobile/shared/models/conversation_summary.dart';
import 'package:driveops_mobile/features/chat/presentation/providers/chat_signalr_provider.dart';

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
}
