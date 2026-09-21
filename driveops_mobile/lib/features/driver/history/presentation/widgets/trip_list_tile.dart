import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:driveops_mobile/shared/models/trip.dart';
import 'trip_status_chip.dart';

class TripListTile extends StatelessWidget {
  final Trip trip;
  final VoidCallback onTap;

  const TripListTile({super.key, required this.trip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, HH:mm');

    return Material(
      color: const Color(0xFF1A1A2E),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
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
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TripStatusChip(status: trip.tripStatus),
                ],
              ),
              const SizedBox(height: 10),
              _addressRow(Icons.radio_button_checked, const Color(0xFF22C55E),
                  trip.pickupAddress),
              const SizedBox(height: 4),
              _addressRow(
                  Icons.location_on, const Color(0xFFEF4444), trip.dropoffAddress),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    dateFormat.format(trip.requestedAt.toLocal()),
                    style:
                        const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                  const Spacer(),
                  if (trip.actualFare != null)
                    Text(
                      '\$${trip.actualFare!.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  else if (trip.estimatedFare != null)
                    Text(
                      '~\$${trip.estimatedFare!.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 13,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _addressRow(IconData icon, Color color, String address) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            address,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
