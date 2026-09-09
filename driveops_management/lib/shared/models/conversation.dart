class Conversation {
  final String id;
  final String? tripId;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> participantUserIds;
  final int unreadCount;

  const Conversation({
    required this.id,
    this.tripId,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    required this.participantUserIds,
    required this.unreadCount,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as String,
      tripId: json['tripId'] as String?,
      isActive: json['isActive'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      participantUserIds: (json['participantUserIds'] as List<dynamic>)
          .map((e) => e.toString())
          .toList(),
      unreadCount: json['unreadCount'] as int,
    );
  }
}