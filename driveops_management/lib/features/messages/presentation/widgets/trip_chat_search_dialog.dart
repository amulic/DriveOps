import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driveops_management/services/chat_api_service.dart';
import 'package:driveops_management/shared/models/conversation_summary.dart';
import 'package:driveops_management/shared/models/trip.dart';
import 'package:driveops_management/shared/providers/repository_providers.dart';
import 'package:driveops_management/features/messages/presentation/providers/conversations_provider.dart';

class TripChatSearchDialog extends ConsumerStatefulWidget {
  const TripChatSearchDialog({super.key});

  @override
  ConsumerState<TripChatSearchDialog> createState() => _TripChatSearchDialogState();
}

class _TripChatSearchDialogState extends ConsumerState<TripChatSearchDialog> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tripsAsync = ref.watch(allTripsProvider);

    return Dialog(
      backgroundColor: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 700,
        height: 600,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Text('Active Trip Chats', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
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
                onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search by trip ID, driver, or customer...',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                  prefixIcon: const Icon(Icons.search, color: Colors.white54),
                  filled: true,
                  fillColor: const Color(0xFF252538),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: tripsAsync.when(
                data: (trips) {
                  final activeTrips = trips.where((t) =>
                      t.tripStatus == TripStatus.assigned ||
                      t.tripStatus == TripStatus.inProgress ||
                      t.tripStatus == TripStatus.driverEnRoute).toList();

                  final filtered = activeTrips.where((t) {
                    if (_searchQuery.isEmpty) return true;
                    return t.id.toLowerCase().contains(_searchQuery) ||
                        (t.driverName?.toLowerCase().contains(_searchQuery) ?? false) ||
                        (t.customerName?.toLowerCase().contains(_searchQuery) ?? false);
                  }).toList();

                  if (filtered.isEmpty) {
                    return const Center(child: Text('No active trips found', style: TextStyle(color: Colors.white54)));
                  }

                  return _TripList(trips: filtered);
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Center(child: Text('Error loading trips', style: TextStyle(color: Colors.white54))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TripList extends ConsumerStatefulWidget {
  final List<Trip> trips;

  const _TripList({required this.trips});

  @override
  ConsumerState<_TripList> createState() => _TripListState();
}

class _TripListState extends ConsumerState<_TripList> {
  List<ConversationSummary>? _tripConversations;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTripConversations();
  }

  Future<void> _loadTripConversations() async {
    try {
      final chatApi = ref.read(chatApiServiceProvider);
      final conversations = await chatApi.getActiveTripConversations();
      if (mounted) {
        setState(() {
          _tripConversations = conversations;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: widget.trips.length,
      itemBuilder: (context, index) {
        final trip = widget.trips[index];
        final existingConv = _tripConversations?.where((c) => c.tripId == trip.id).firstOrNull;
        final hasConversation = existingConv != null && existingConv.id.isNotEmpty;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF252538),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.directions_car, color: Color(0xFF3B82F6), size: 20),
            ),
            title: Row(
              children: [
                Text('Trip ${trip.id.substring(0, 8)}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _statusColor(trip.tripStatus).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _statusLabel(trip.tripStatus),
                    style: TextStyle(color: _statusColor(trip.tripStatus), fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            subtitle: Text(
              'Driver: ${trip.driverName ?? "Unassigned"} | Customer: ${trip.customerName ?? "N/A"}',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
            ),
            trailing: FilledButton(
              onPressed: () => _joinConversation(hasConversation ? existingConv.id : '', trip),
              style: FilledButton.styleFrom(
                backgroundColor: hasConversation ? const Color(0xFF22C55E) : const Color(0xFF3B82F6),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: Text(hasConversation ? 'Join Chat' : 'Create & Join',
                  style: const TextStyle(fontSize: 12)),
            ),
          ),
        );
      },
    );
  }

  Future<void> _joinConversation(String conversationId, Trip trip) async {
    try {
      if (conversationId.isNotEmpty) {
        await ref.read(conversationsProvider.notifier).joinTripConversation(conversationId);
      } else {
        final chatApi = ref.read(chatApiServiceProvider);
        final tripConvs = await chatApi.getActiveTripConversations();
        final match = tripConvs.firstWhere(
          (c) => c.tripId == trip.id,
        );
        await chatApi.joinConversation(match.id);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to join conversation: $e')),
        );
      }
    }
  }

  Color _statusColor(TripStatus status) {
    switch (status) {
      case TripStatus.assigned: return const Color(0xFF3B82F6);
      case TripStatus.driverEnRoute: return const Color(0xFFF59E0B);
      case TripStatus.inProgress: return const Color(0xFF22C55E);
      default: return Colors.white54;
    }
  }

  String _statusLabel(TripStatus status) {
    switch (status) {
      case TripStatus.assigned: return 'Assigned';
      case TripStatus.driverEnRoute: return 'En Route';
      case TripStatus.inProgress: return 'In Progress';
      default: return status.name;
    }
  }
}