class ConversationSummary {
  final String id;
  final String? tripId;
  final String conversationType;
  final DateTime lastMessageAt;
  final int unreadCount;
  final List<String> participantUserIds;

  const ConversationSummary({
    required this.id,
    this.tripId,
    required this.conversationType,
    required this.lastMessageAt,
    required this.unreadCount,
    required this.participantUserIds,
  });

  factory ConversationSummary.fromJson(Map<String, dynamic> json) {
    return ConversationSummary(
      id: json['id'] as String,
      tripId: json['tripId'] as String?,
      conversationType: json['conversationType'] as String,
      lastMessageAt: DateTime.parse(json['lastMessageAt'] as String),
      unreadCount: json['unreadCount'] as int,
      participantUserIds: (json['participantUserIds'] as List<dynamic>)
          .map((e) => e.toString())
          .toList(),
    );
  }
}