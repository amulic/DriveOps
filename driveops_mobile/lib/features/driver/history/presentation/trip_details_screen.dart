import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:driveops_mobile/shared/models/trip.dart';
import 'widgets/trip_status_chip.dart';

/// Full detail view of a single trip, opened from the history list.
class TripDetailsScreen extends StatelessWidget {
  final Trip trip;

  const TripDetailsScreen({super.key, required this.trip});

  static final _dateFormat = DateFormat('MMM d, yyyy · HH:mm');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Trip Details'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        trip.customerName ?? 'Customer',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    TripStatusChip(status: trip.tripStatus),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _tripTypeLabel(trip.tripType),
                  style: const TextStyle(color: Colors.white38, fontSize: 13),
                ),
                if (trip.vehiclePlate != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Vehicle: ${trip.vehiclePlate}',
                    style: const TextStyle(color: Colors.white38, fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle('Route'),
                const SizedBox(height: 12),
                _addressRow(Icons.radio_button_checked,
                    const Color(0xFF22C55E), 'Pickup', trip.pickupAddress),
                const SizedBox(height: 10),
                _addressRow(Icons.location_on, const Color(0xFFEF4444),
                    'Dropoff', trip.dropoffAddress),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle('Timeline'),
                const SizedBox(height: 12),
                _timeRow('Requested', trip.requestedAt),
                _timeRow('Scheduled', trip.scheduledAt),
                _timeRow('Assigned', trip.assignedAt),
                _timeRow('Picked up', trip.pickupTime),
                _timeRow('Dropped off', trip.dropoffTime),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle('Fare & Distance'),
                const SizedBox(height: 12),
                _metricRow('Distance', trip.actualDistance, trip.estimatedDistance, 'km'),
                _metricRow('Duration', trip.actualDuration, trip.estimatedDuration, 'min'),
                _metricRow('Fare', trip.actualFare, trip.estimatedFare, '', prefix: '\$'),
                if (trip.paymentMethod != null)
                  _plainRow('Payment', _paymentLabel(trip.paymentMethod!)),
              ],
            ),
          ),
          if (trip.customerRating != null || trip.driverRating != null) ...[
            const SizedBox(height: 12),
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('Ratings'),
                  const SizedBox(height: 12),
                  if (trip.customerRating != null)
                    _plainRow('Customer rated you', '${trip.customerRating} / 5'),
                  if (trip.driverRating != null)
                    _plainRow('You rated customer', '${trip.driverRating} / 5'),
                ],
              ),
            ),
          ],
          if (trip.cancellationReason != null &&
              trip.cancellationReason!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle(trip.tripStatus == TripStatus.declined
                      ? 'Decline reason'
                      : 'Cancellation reason'),
                  const SizedBox(height: 8),
                  Text(
                    trip.cancellationReason!,
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: child,
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _addressRow(IconData icon, Color color, String label, String address) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style:
                      const TextStyle(color: Colors.white38, fontSize: 11)),
              Text(
                address,
                style:
                    const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _timeRow(String label, DateTime? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style:
                    const TextStyle(color: Colors.white54, fontSize: 13)),
          ),
          Text(
            value != null ? _dateFormat.format(value.toLocal()) : '—',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _metricRow(String label, num? actual, num? estimated, String unit,
      {String prefix = ''}) {
    String fmt(num? v) => v == null
        ? '—'
        : '$prefix${v is double ? v.toStringAsFixed(2) : v}${unit.isNotEmpty ? ' $unit' : ''}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style:
                    const TextStyle(color: Colors.white54, fontSize: 13)),
          ),
          Text(
            fmt(actual),
            style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600),
          ),
          if (actual == null && estimated != null)
            Text(
              '  (est. ${fmt(estimated)})',
              style:
                  const TextStyle(color: Colors.white38, fontSize: 12),
            ),
        ],
      ),
    );
  }

  Widget _plainRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style:
                    const TextStyle(color: Colors.white54, fontSize: 13)),
          ),
          Text(value,
              style:
                  const TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }

  String _tripTypeLabel(TripType type) => switch (type) {
        TripType.standard => 'Standard',
        TripType.premium => 'Premium',
        TripType.shared => 'Shared',
        TripType.scheduled => 'Scheduled',
      };

  String _paymentLabel(PaymentMethod method) => switch (method) {
        PaymentMethod.cash => 'Cash',
        PaymentMethod.creditCard => 'Credit card',
        PaymentMethod.debitCard => 'Debit card',
        PaymentMethod.digitalWallet => 'Digital wallet',
      };
}
