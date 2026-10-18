import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:driveops_mobile/features/chat/presentation/chat_thread_screen.dart';
import 'package:driveops_mobile/features/customer/providers/customer_providers.dart';
import 'package:driveops_mobile/services/chat_api_service.dart';
import 'package:driveops_mobile/shared/models/trip.dart';
import 'package:driveops_mobile/shared/providers/auth_provider.dart';
import 'package:driveops_mobile/shared/widgets/trip_status_chip.dart';

/// The customer's live trip: status, route summary, driver/vehicle once
/// assigned, cancel (until pickup) and chat with the driver (from assigned).
class CustomerTripScreen extends ConsumerWidget {
  const CustomerTripScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTripAsync = ref.watch(customerActiveTripProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Current trip'),
      ),
      body: activeTripAsync.when(
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
                  'Failed to load your trip: $e',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white54, fontSize: 14),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => ref.invalidate(customerActiveTripProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (trip) => trip == null
            ? const _NoActiveTrip()
            : _ActiveTripView(trip: trip),
      ),
    );
  }
}

class _NoActiveTrip extends StatelessWidget {
  const _NoActiveTrip();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_taxi_outlined,
                size: 64, color: Colors.white.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            const Text(
              'No active trip',
              style: TextStyle(color: Colors.white54, fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.go('/customer/request'),
              icon: const Icon(Icons.add_road),
              label: const Text('Request a trip'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveTripView extends ConsumerWidget {
  final Trip trip;

  const _ActiveTripView({required this.trip});

  bool get _isRequested => trip.tripStatus == TripStatus.requested;
  bool get _hasDriver =>
      trip.tripStatus == TripStatus.assigned ||
      trip.tripStatus == TripStatus.driverEnRoute ||
      trip.tripStatus == TripStatus.inProgress;
  bool get _canCancel => trip.tripStatus != TripStatus.inProgress;

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Cancel trip?',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'The trip will be cancelled and you can request a new one.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Back'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444)),
            child: const Text('Cancel trip'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(customerTripActionsProvider).cancelActiveTrip(trip.id);
      if (context.mounted) context.go('/customer');
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Could not cancel the trip. Please try again.')),
        );
      }
    }
  }

  Future<void> _openChat(BuildContext context, WidgetRef ref) async {
    try {
      final summary =
          await ref.read(customerTripConversationProvider(trip.id).future);
      if (summary == null) {
        // Event race right after assignment — the conversation is created
        // server-side on trip.assigned and may take a moment to appear.
        ref.invalidate(customerTripConversationProvider(trip.id));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Chat will be available shortly — try again.')),
          );
        }
        return;
      }

      final chatApi = ref.read(chatApiServiceProvider);
      final conversation = await chatApi.getConversation(summary.id);
      final currentUserName =
          ref.read(authProvider).value?.user?.fullName ?? 'Me';
      final currentUserId = ref.read(keycloakSubProvider) ?? '';
      if (context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChatThreadScreen(
              conversation: conversation,
              currentUserDisplayName: currentUserName,
              currentUserId: currentUserId,
            ),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the chat.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestedAt =
        DateFormat('MMM d, HH:mm').format(trip.requestedAt.toLocal());

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            TripStatusChip(status: trip.tripStatus),
            const Spacer(),
            Text(
              requestedAt,
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (_isRequested)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF3B82F6),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Looking for a driver…',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        _InfoCard(
          children: [
            _AddressRow(
              icon: Icons.trip_origin,
              color: const Color(0xFF22C55E),
              label: 'Pickup',
              value: trip.pickupAddress,
            ),
            const SizedBox(height: 14),
            _AddressRow(
              icon: Icons.location_on,
              color: const Color(0xFFEF4444),
              label: 'Dropoff',
              value: trip.dropoffAddress,
            ),
            if (trip.estimatedFare != null) ...[
              const Divider(color: Colors.white12, height: 28),
              Row(
                children: [
                  const Icon(Icons.payments_outlined,
                      color: Colors.white38, size: 18),
                  const SizedBox(width: 10),
                  const Text('Estimated fare',
                      style: TextStyle(color: Colors.white54, fontSize: 13)),
                  const Spacer(),
                  Text(
                    '\$${trip.estimatedFare!.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        if (_hasDriver) ...[
          const SizedBox(height: 16),
          _InfoCard(
            children: [
              _AddressRow(
                icon: Icons.person_outline,
                color: const Color(0xFF8B5CF6),
                label: 'Driver',
                value: trip.driverName ?? 'Your driver',
              ),
              if (trip.vehiclePlate != null) ...[
                const SizedBox(height: 14),
                _AddressRow(
                  icon: Icons.directions_car_outlined,
                  color: const Color(0xFF06B6D4),
                  label: 'Vehicle',
                  value: trip.vehiclePlate!,
                ),
              ],
            ],
          ),
        ],
        const SizedBox(height: 28),
        if (_hasDriver)
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () => _openChat(context, ref),
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text(
                'Chat with driver',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        if (_hasDriver && _canCancel) const SizedBox(height: 12),
        if (_canCancel)
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () => _cancel(context, ref),
              icon: const Icon(Icons.close),
              label: const Text(
                'Cancel trip',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFEF4444),
                side: BorderSide(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.5)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;

  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _AddressRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _AddressRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
