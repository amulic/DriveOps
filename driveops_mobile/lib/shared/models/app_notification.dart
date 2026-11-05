class AppNotification {
  final String id;
  final String type;
  final String title;
  final String message;
  final String? tripId;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.tripId,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      tripId: json['tripId'] as String?,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: DateTime.parse(json['timestamp'] as String),
    );
  }
}

class PagedNotifications {
  final int totalCount;
  final int unreadCount;
  final List<AppNotification> items;

  const PagedNotifications({
    required this.totalCount,
    required this.unreadCount,
    required this.items,
  });

  factory PagedNotifications.fromJson(Map<String, dynamic> json) {
    return PagedNotifications(
      totalCount: json['totalCount'] as int,
      unreadCount: json['unreadCount'] as int,
      items: (json['items'] as List<dynamic>)
          .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
