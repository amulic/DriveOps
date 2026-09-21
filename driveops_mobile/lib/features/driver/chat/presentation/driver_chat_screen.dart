import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driveops_mobile/shared/models/conversation_summary.dart';
import 'package:driveops_mobile/services/chat_api_service.dart';
import 'package:driveops_mobile/features/driver/chat/presentation/providers/conversations_provider.dart';
import 'package:driveops_mobile/features/driver/chat/presentation/providers/user_names_provider.dart';
import 'package:driveops_mobile/features/driver/chat/presentation/chat_thread_screen.dart';
import 'package:driveops_mobile/shared/providers/auth_provider.dart';
import 'package:driveops_mobile/shared/utils/id_display.dart';

class DriverChatScreen extends ConsumerWidget {
  const DriverChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(conversationsProvider);
    final currentUserId = ref.watch(keycloakSubProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Chat'),
      ),
      body: conversationsAsync.when(
        data: (conversations) {
          final directMessages =
              conversations.where((c) => c.conversationType == 'direct').toList();
          final tripChats =
              conversations.where((c) => c.conversationType == 'trip').toList();

          return RefreshIndicator(
            onRefresh: () => ref.read(conversationsProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                if (tripChats.isNotEmpty) ...[
                  _buildSectionHeader('Trip Chats'),
                  const SizedBox(height: 8),
                  ...tripChats.map((c) => _ConversationTile(
                        conversation: c,
                        currentUserId: currentUserId,
                        onTap: () => _openConversation(context, ref, c.id),
                      )),
                  const SizedBox(height: 16),
                ],
                if (directMessages.isNotEmpty) ...[
                  _buildSectionHeader('Direct Messages'),
                  const SizedBox(height: 8),
                  ...directMessages.map((c) => _ConversationTile(
                        conversation: c,
                        currentUserId: currentUserId,
                        onTap: () => _openConversation(context, ref, c.id),
                      )),
                ],
                if (conversations.isEmpty) _buildEmptyState(),
              ],
            ),
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6))),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 48),
                const SizedBox(height: 16),
                Text('Failed to load chats: $e',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () =>
                      ref.read(conversationsProvider.notifier).refresh(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Text(title,
            style: const TextStyle(
                color: Colors.white54,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2)),
        const Expanded(
            child: Padding(
                padding: EdgeInsets.only(left: 12),
                child: Divider(color: Colors.white12))),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 120),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_rounded,
                size: 64, color: Colors.white.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            const Text('No conversations yet',
                style: TextStyle(color: Colors.white54, fontSize: 16)),
            const SizedBox(height: 8),
            const Text('Trip chats appear once a ride is assigned to you',
                style: TextStyle(color: Colors.white38, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  void _openConversation(
      BuildContext context, WidgetRef ref, String conversationId) async {
    final chatApi = ref.read(chatApiServiceProvider);
    final conversation = await chatApi.getConversation(conversationId);
    final currentUserName =
        ref.read(authProvider).value?.user?.fullName ?? 'Me';
    final currentUserId = ref.read(keycloakSubProvider) ?? '';
    if (context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatThreadScreen(
            conversation: conversation,
            currentUserDisplayName: currentUserName,
            currentUserId: currentUserId,
          ),
        ),
      );
    }
  }
}

class _ConversationTile extends ConsumerWidget {
  final ConversationSummary conversation;
  final String? currentUserId;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.conversation,
    required this.currentUserId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isTrip = conversation.conversationType == 'trip';
    final otherIds = conversation.participantUserIds
        .where((id) => id != currentUserId)
        .toList();
    final userNamesAsync = ref.watch(userNamesProvider(otherIds.join(',')));

    final displayName = isTrip
        ? 'Trip ${conversation.tripId == null ? "" : shortId(conversation.tripId!, take: 8)}...'
        : userNamesAsync.when(
            data: (names) =>
                names.values.isEmpty ? 'Unknown' : names.values.join(', '),
            loading: () => 'Loading...',
            error: (_, _) => 'Unknown',
          );

    final subtitle = isTrip
        ? userNamesAsync.when(
            data: (names) => names.values.join(', '),
            loading: () => 'Loading...',
            error: (_, _) => '',
          )
        : 'Direct Message';

    final timeAgo = _formatTimeAgo(conversation.lastMessageAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: const Color(0xFF252538),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isTrip
                        ? const Color(0xFF22C55E).withValues(alpha: 0.15)
                        : const Color(0xFF3B82F6).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isTrip ? Icons.directions_car : Icons.person,
                    color: isTrip
                        ? const Color(0xFF22C55E)
                        : const Color(0xFF3B82F6),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                              child: Text(displayName,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14))),
                          Text(timeAgo,
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                if (conversation.unreadCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${conversation.unreadCount}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${dt.day}/${dt.month}';
  }
}
