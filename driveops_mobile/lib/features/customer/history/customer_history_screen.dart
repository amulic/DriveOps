import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:driveops_mobile/features/customer/providers/customer_providers.dart';
import 'package:driveops_mobile/services/cache_service.dart';
import 'package:driveops_mobile/shared/models/trip.dart';
import 'package:driveops_mobile/shared/providers/repository_providers.dart';
import 'package:driveops_mobile/shared/widgets/rate_trip_dialog.dart';
import 'package:driveops_mobile/shared/widgets/trip_status_chip.dart';

/// The customer's trips: the live trip pinned on top, past trips newest-first
/// below (server ordering).
String _paymentLabel(PaymentMethod method) => switch (method) {
      PaymentMethod.cash => 'Cash',
      PaymentMethod.creditCard => 'Credit card',
      PaymentMethod.debitCard => 'Debit card',
      PaymentMethod.digitalWallet => 'Digital wallet',
    };

class CustomerHistoryScreen extends ConsumerWidget {
  const CustomerHistoryScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    // Bust the Hive cache first — invalidating alone would re-read the cache.
    final customer = await ref.read(currentCustomerProvider.future);
    if (customer != null) {
      await ref
          .read(cacheServiceProvider)
          .remove(CacheService.tripsCustomer(customer.id));
    }
    ref.invalidate(customerTripsProvider);
    ref.invalidate(customerActiveTripProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsAsync = ref.watch(customerTripsProvider);
    final activeTrip = ref.watch(customerActiveTripProvider).value;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Trip history'),
      ),
      body: tripsAsync.when(
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
                  'Failed to load your trips: $e',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white54, fontSize: 14),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => _refresh(ref),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (trips) {
          final past =
              trips.where((t) => t.id != activeTrip?.id).toList(growable: false);

          return RefreshIndicator(
            onRefresh: () => _refresh(ref),
            color: const Color(0xFF3B82F6),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                if (activeTrip != null) ...[
                  _ActiveTripTile(
                    trip: activeTrip,
                    onTap: () => context.push('/customer/trip'),
                  ),
                  const SizedBox(height: 16),
                ],
                if (past.isEmpty && activeTrip == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 120),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.history,
                              size: 64,
                              color: Colors.white.withValues(alpha: 0.2)),
                          const SizedBox(height: 16),
                          const Text(
                            'No trips yet',
                            style: TextStyle(
                                color: Colors.white54, fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Your requested trips will show up here',
                            style: TextStyle(
                                color: Colors.white38, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...past.map((t) => _TripTile(trip: t)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ActiveTripTile extends StatelessWidget {
  final Trip trip;
  final VoidCallback onTap;

  const _ActiveTripTile({required this.trip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current trip',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${trip.pickupAddress} → ${trip.dropoffAddress}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              TripStatusChip(status: trip.tripStatus),
            ],
          ),
        ),
      ),
    );
  }
}

class _TripTile extends ConsumerWidget {
  final Trip trip;

  const _TripTile({required this.trip});

  bool get _canRate =>
      trip.tripStatus == TripStatus.completed && trip.customerRating == null;

  Future<void> _rate(BuildContext context, WidgetRef ref) async {
    final request = await RateTripDialog.show(
      context,
      title: 'Rate your driver',
      isCustomerRating: true,
    );
    if (request == null || !context.mounted) return;

    try {
      await ref.read(tripRepositoryProvider).rateTrip(trip.id, request);
      ref.invalidate(customerTripsProvider);
      ref.invalidate(customerActiveTripProvider);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Could not submit your rating. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = DateFormat('MMM d, yyyy · HH:mm').format(trip.requestedAt.toLocal());
    final fare = trip.actualFare ?? trip.estimatedFare;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => _showDetails(context, ref),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        date,
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 12),
                      ),
                    ),
                    TripStatusChip(status: trip.tripStatus),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${trip.pickupAddress} → ${trip.dropoffAddress}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 14),
                      ),
                    ),
                    if (fare != null) ...[
                      const SizedBox(width: 12),
                      Text(
                        '\$${fare.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
                if (trip.customerRating != null) ...[
                  const SizedBox(height: 8),
                  RatingStars(rating: trip.customerRating!),
                ] else if (_canRate) ...[
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => _rate(context, ref),
                      icon: const Icon(Icons.star_border, size: 16),
                      label: const Text('Rate'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFF59E0B),
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 32),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDetails(BuildContext context, WidgetRef ref) {
    final date =
        DateFormat('MMM d, yyyy · HH:mm').format(trip.requestedAt.toLocal());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Row(
          children: [
            const Expanded(
              child: Text('Trip details',
                  style: TextStyle(color: Colors.white, fontSize: 17)),
            ),
            TripStatusChip(status: trip.tripStatus),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DetailLine(label: 'Requested', value: date),
            _DetailLine(label: 'Pickup', value: trip.pickupAddress),
            _DetailLine(label: 'Dropoff', value: trip.dropoffAddress),
            if (trip.driverName != null)
              _DetailLine(label: 'Driver', value: trip.driverName!),
            if (trip.vehiclePlate != null)
              _DetailLine(label: 'Vehicle', value: trip.vehiclePlate!),
            if (trip.estimatedFare != null)
              _DetailLine(
                label: trip.actualFare != null ? 'Final fare' : 'Estimated fare',
                value:
                    '\$${(trip.actualFare ?? trip.estimatedFare)!.toStringAsFixed(2)}',
              ),
            if (trip.paymentMethod != null)
              _DetailLine(
                  label: 'Payment',
                  value: _paymentLabel(trip.paymentMethod!)),
            if (trip.customerRating != null)
              _DetailLine(
                  label: 'Your rating', value: '${trip.customerRating} / 5'),
            if (trip.cancellationReason != null)
              _DetailLine(label: 'Cancel reason', value: trip.cancellationReason!),
          ],
        ),
        actions: [
          if (_canRate)
            TextButton.icon(
              onPressed: () {
                Navigator.of(ctx).pop();
                _rate(context, ref);
              },
              icon: const Icon(Icons.star_border, size: 16),
              label: const Text('Rate'),
              style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFF59E0B)),
            ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  final String label;
  final String value;

  const _DetailLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white38, fontSize: 11)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(color: Colors.white, fontSize: 13)),
        ],
      ),
    );
  }
}
