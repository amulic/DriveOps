import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driveops_mobile/shared/models/app_notification.dart';
import 'package:driveops_mobile/shared/providers/notifications_provider.dart';

/// Persistent notification center shared by drivers and customers.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final unread = ref.watch(unreadNotificationsCountProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Notifications'),
        actions: [
          if (unread > 0)
            TextButton(
              onPressed: () => ref.read(notificationActionsProvider).markAllRead(),
              child: const Text(
                'Mark all read',
                style: TextStyle(color: Color(0xFF3B82F6)),
              ),
            ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline,
                    color: Color(0xFFEF4444), size: 40),
                const SizedBox(height: 16),
                Text(
                  'Failed to load notifications: $e',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white54, fontSize: 14),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => ref.invalidate(notificationsProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (paged) {
          final items = paged.items;
          if (items.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_none,
                      color: Colors.white24, size: 48),
                  SizedBox(height: 12),
                  Text(
                    'No notifications yet',
                    style: TextStyle(color: Colors.white38, fontSize: 14),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: const Color(0xFF3B82F6),
            onRefresh: () async => ref.invalidate(notificationsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: items.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, color: Color(0xFF23233A)),
              itemBuilder: (context, index) =>
                  _NotificationTile(notification: items[index]),
            ),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  final AppNotification notification;

  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = !notification.isRead;

    return ListTile(
      tileColor:
          unread ? const Color(0xFF3B82F6).withValues(alpha: 0.08) : null,
      leading: Icon(
        _iconFor(notification.type),
        color: unread ? const Color(0xFF3B82F6) : Colors.white38,
      ),
      title: Text(
        notification.title,
        style: TextStyle(
          color: unread ? Colors.white : Colors.white70,
          fontWeight: unread ? FontWeight.w600 : FontWeight.w400,
          fontSize: 14,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.message,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(notification.createdAt),
              style: const TextStyle(color: Colors.white30, fontSize: 11),
            ),
          ],
        ),
      ),
      trailing: unread
          ? Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF3B82F6),
                shape: BoxShape.circle,
              ),
            )
          : null,
      onTap: unread
          ? () => ref
              .read(notificationActionsProvider)
              .markRead(notification.id)
          : null,
    );
  }

  static IconData _iconFor(String type) {
    switch (type) {
      case 'TripAssigned':
        return Icons.local_taxi_outlined;
      case 'TripStarted':
        return Icons.play_circle_outline;
      case 'TripCompleted':
        return Icons.check_circle_outline;
      case 'TripCancelled':
        return Icons.cancel_outlined;
      case 'TripDeclined':
        return Icons.do_not_disturb_on_outlined;
      default:
        return Icons.notifications_none;
    }
  }

  static String _formatTime(DateTime utc) {
    final local = utc.toLocal();
    final diff = DateTime.now().difference(local);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }
}
