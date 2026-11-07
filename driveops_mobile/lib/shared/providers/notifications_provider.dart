import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driveops_mobile/services/notification_api_service.dart';
import 'package:driveops_mobile/shared/models/app_notification.dart';
import 'package:driveops_mobile/shared/providers/notification_signalr_provider.dart';

/// The current user's persisted notifications (newest first) with the unread
/// count. The REST list is the source of truth: the `SystemNotification`
/// SignalR push only invalidates this provider, so offline deliveries are
/// recovered on the next open/refresh.
final notificationsProvider = FutureProvider.autoDispose<PagedNotifications>((ref) {
  return ref.watch(notificationApiServiceProvider).getNotifications();
});

/// Unread badge count (0 while loading/error).
final unreadNotificationsCountProvider = Provider.autoDispose<int>((ref) {
  return ref.watch(notificationsProvider).maybeWhen(
        data: (paged) => paged.unreadCount,
        orElse: () => 0,
      );
});

/// Refresh the inbox whenever the server pushes a persisted notification.
final notificationPushListenerProvider = Provider<void>((ref) {
  ref.watch(notificationSignalrConnectionProvider);
  final signalr = ref.watch(notificationSignalrServiceProvider);

  void handler(List<dynamic>? args) {
    ref.invalidate(notificationsProvider);
  }

  signalr.on('SystemNotification', handler);
  ref.onDispose(() => signalr.off('SystemNotification'));
});

/// Mark-as-read mutations (single + all) followed by an inbox refresh.
class NotificationActions {
  final Ref _ref;

  NotificationActions(this._ref);

  Future<void> markRead(String id) async {
    await _ref.read(notificationApiServiceProvider).markAsRead(id);
    _ref.invalidate(notificationsProvider);
  }

  Future<void> markAllRead() async {
    await _ref.read(notificationApiServiceProvider).markAllAsRead();
    _ref.invalidate(notificationsProvider);
  }
}

final notificationActionsProvider =
    Provider<NotificationActions>((ref) => NotificationActions(ref));
