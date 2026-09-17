import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driveops_management/shared/providers/repository_providers.dart';
import 'package:driveops_management/shared/models/driver.dart';
import 'package:driveops_management/features/messages/presentation/providers/conversations_provider.dart';

class NewConversationDialog extends ConsumerStatefulWidget {
  const NewConversationDialog({super.key});

  @override
  ConsumerState<NewConversationDialog> createState() =>
      _NewConversationDialogState();
}

class _NewConversationDialogState extends ConsumerState<NewConversationDialog> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final driversAsync = ref.watch(activeDriversProvider);

    return Dialog(
      backgroundColor: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 500,
        height: 500,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Text(
                    'New Conversation',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white54),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                onChanged: (v) =>
                    setState(() => _searchQuery = v.toLowerCase()),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search drivers...',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                  prefixIcon: const Icon(Icons.search, color: Colors.white54),
                  filled: true,
                  fillColor: const Color(0xFF252538),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: driversAsync.when(
                data: (drivers) {
                  final filtered = drivers.where(
                    (d) =>
                        _searchQuery.isEmpty ||
                        d.driverName.toLowerCase().contains(_searchQuery) ||
                        d.email.toLowerCase().contains(_searchQuery),
                  );
                  if (filtered.isEmpty) {
                    return const Center(
                      child: Text(
                        'No drivers found',
                        style: TextStyle(color: Colors.white54),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final driver = filtered.elementAt(index);
                      return _DriverTile(
                        driver: driver,
                        onTap: () => _createConversation(driver),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Center(
                  child: Text(
                    'Error loading drivers',
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createConversation(Driver driver) async {
    try {
      final otherUserId = driver.keycloakId;
      await ref
          .read(conversationsProvider.notifier)
          .createDirectConversation(otherUserId);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create conversation: $e')),
        );
      }
    }
  }
}

class _DriverTile extends StatelessWidget {
  final Driver driver;
  final VoidCallback onTap;

  const _DriverTile({required this.driver, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final initials = driver.driverName
        .split(' ')
        .take(2)
        .map((n) => n.isNotEmpty ? n[0] : '')
        .join()
        .toUpperCase();

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: const Color(0xFF3B82F6),
        child: Text(
          initials,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
      ),
      title: Text(
        driver.driverName,
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
      subtitle: Text(
        driver.email,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.5),
          fontSize: 12,
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: driver.isOnline ? const Color(0xFF22C55E) : Colors.white24,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          driver.isOnline ? 'Online' : driver.status.name,
          style: const TextStyle(color: Colors.white, fontSize: 11),
        ),
      ),
      onTap: onTap,
    );
  }
}
