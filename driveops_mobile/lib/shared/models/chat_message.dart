class PagedMessages {
  final int totalCount;
  final int page;
  final int pageSize;
  final List<ChatMessage> messages;

  const PagedMessages({
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.messages,
  });

  factory PagedMessages.fromJson(Map<String, dynamic> json) {
    return PagedMessages(
      totalCount: json['totalCount'] as int,
      page: json['page'] as int,
      pageSize: json['pageSize'] as int,
      messages: (json['messages'] as List<dynamic>)
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ChatMessage {
  final String id;
  final String conversationId;
  final String senderUserId;
  final String content;
  final DateTime sentAt;

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderUserId,
    required this.content,
    required this.sentAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      conversationId: json['conversationId'] as String,
      senderUserId: json['senderUserId'] as String,
      content: json['content'] as String,
      sentAt: DateTime.parse(json['sentAt'] as String),
    );
  }
}