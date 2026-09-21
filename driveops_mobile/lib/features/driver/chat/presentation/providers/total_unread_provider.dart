import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driveops_mobile/features/driver/chat/presentation/providers/conversations_provider.dart';

final totalUnreadProvider = Provider<int>((ref) {
  final conversationsAsync = ref.watch(conversationsProvider);
  return conversationsAsync.when(
    data: (conversations) => conversations.fold(0, (sum, c) => sum + c.unreadCount),
    loading: () => 0,
    error: (_, _) => 0,
  );
});
