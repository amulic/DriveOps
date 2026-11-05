import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driveops_mobile/features/notifications/notifications_screen.dart';
import 'package:driveops_mobile/shared/providers/notifications_provider.dart';

/// Bell-with-badge AppBar action that opens the notification center.
class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadNotificationsCountProvider);

    return IconButton(
      tooltip: 'Notifications',
      icon: Badge(
        isLabelVisible: unread > 0,
        label: Text('$unread'),
        child: const Icon(Icons.notifications_none),
      ),
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const NotificationsScreen()),
      ),
    );
  }
}
