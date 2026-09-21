import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driveops_management/shared/models/chat_message.dart';
import 'package:driveops_management/shared/models/conversation.dart';
import 'package:driveops_management/features/messages/presentation/providers/messages_provider.dart';
import 'package:driveops_management/features/messages/presentation/providers/chat_signalr_provider.dart';
import 'package:driveops_management/features/messages/presentation/providers/user_names_provider.dart';
import 'package:driveops_management/services/chat_signalr_service.dart';
import 'package:driveops_management/shared/utils/id_display.dart';

class ChatThreadScreen extends ConsumerStatefulWidget {
  final Conversation conversation;
  final String currentUserDisplayName;
  final String currentUserId;

  const ChatThreadScreen({
    super.key,
    required this.conversation,
    required this.currentUserDisplayName,
    required this.currentUserId,
  });

  @override
  ConsumerState<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends ConsumerState<ChatThreadScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  late final ChatSignalrService _chatSignalr;
  late List<ChatMessage> _messages;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _chatSignalr = ref.read(chatSignalrServiceProvider);
    _chatSignalr.joinConversationGroup(widget.conversation.id);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chatSignalr.markAsRead(widget.conversation.id);
    });
  }

  @override
  void dispose() {
    _chatSignalr.leaveConversationGroup(widget.conversation.id);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;
    _messageController.clear();
    _chatSignalr.sendMessage(widget.conversation.id, content);

    final optimisticMsg = ChatMessage(
      id: '_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: widget.conversation.id,
      senderUserId: widget.currentUserId,
      content: content,
      sentAt: DateTime.now(),
    );
    setState(() {
      _messages = [optimisticMsg, ..._messages];
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  List<String> _getOtherUserIds() {
    return widget.conversation.participantUserIds
        .where((id) => id != widget.currentUserId)
        .toList();
  }

  void _listenForMessages() {
    _chatSignalr.on('ReceiveMessage', (args) {
      if (args != null && args.isNotEmpty) {
        final data = args.first as Map<String, dynamic>;
        final msg = ChatMessage.fromJson(data);
        if (msg.conversationId == widget.conversation.id) {
          setState(() {
            if (!_messages.any((m) => m.id == msg.id)) {
              _messages = [msg, ..._messages];
            }
          });
          _scrollToBottom();
        }
      }
    });

    _chatSignalr.on('MessageSent', (args) {
      if (args != null && args.isNotEmpty) {
        final data = args.first as Map<String, dynamic>;
        final msg = ChatMessage.fromJson(data);
        if (msg.conversationId == widget.conversation.id) {
          setState(() {
            _messages = _messages.map((m) => m.id.startsWith('_') && m.content == msg.content ? msg : m).toList();
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final otherUserIds = _getOtherUserIds();
    final userNamesAsync = ref.watch(userNamesProvider(otherUserIds.join(',')));
    final messagesAsync = ref.watch(messagesProvider(widget.conversation.id));

    if (!_initialized) {
      messagesAsync.whenData((msgs) {
        _messages = msgs;
        _initialized = true;
        _listenForMessages();
      });
    }

    final title = widget.conversation.tripId != null
        ? 'Trip ${shortId(widget.conversation.tripId!, take: 8)}...'
        : userNamesAsync.when(
            data: (names) => names.values.join(', '),
            loading: () => 'Direct Message',
            error: (_, __) => 'Direct Message',
          );

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _initialized
                ? _buildMessageList(_messages, userNamesAsync)
                : const Center(child: CircularProgressIndicator()),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildMessageList(List<ChatMessage> messages, AsyncValue<Map<String, String>> userNamesAsync) {
    if (messages.isEmpty) {
      return const Center(
        child: Text('No messages yet. Start the conversation!',
            style: TextStyle(color: Colors.white54)),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msg = messages[index];
        final isMe = msg.senderUserId == widget.currentUserId;
        final senderName = isMe
            ? widget.currentUserDisplayName
            : userNamesAsync.when(
                data: (names) => names[msg.senderUserId] ?? 'Unknown',
                loading: () => '...',
                error: (_, __) => 'Unknown',
              );

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Align(
            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.65),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isMe ? const Color(0xFF3B82F6) : const Color(0xFF252538),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(12),
                    topRight: const Radius.circular(12),
                    bottomLeft: Radius.circular(isMe ? 12 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 12),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    if (!isMe)
                      Text(senderName, style: const TextStyle(fontSize: 11, color: Colors.white54, fontWeight: FontWeight.w600)),
                    if (!isMe) const SizedBox(height: 2),
                    Text(msg.content, style: const TextStyle(color: Colors.white, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(msg.sentAt),
                      style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.5)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                filled: true,
                fillColor: const Color(0xFF252538),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: _sendMessage,
            icon: const Icon(Icons.send_rounded),
            color: const Color(0xFF3B82F6),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF252538),
              padding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${dt.day}/${dt.month}';
    }
  }
}