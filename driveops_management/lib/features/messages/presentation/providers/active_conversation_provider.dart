import 'package:flutter_riverpod/flutter_riverpod.dart';

class ActiveConversationIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? id) => state = id;
}

final activeConversationIdProvider = NotifierProvider<ActiveConversationIdNotifier, String?>(
  ActiveConversationIdNotifier.new,
);