import 'package:flutter/material.dart';
import 'package:driveops_mobile/shared/models/trip.dart';

class TripStatusChip extends StatelessWidget {
  final TripStatus status;

  const TripStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      TripStatus.requested => ('Requested', const Color(0xFF3B82F6)),
      TripStatus.assigned => ('Assigned', const Color(0xFF8B5CF6)),
      TripStatus.driverEnRoute => ('En Route', const Color(0xFF06B6D4)),
      TripStatus.inProgress => ('In Progress', const Color(0xFF06B6D4)),
      TripStatus.completed => ('Completed', const Color(0xFF22C55E)),
      TripStatus.cancelled => ('Cancelled', const Color(0xFFEF4444)),
      TripStatus.noDriverAvailable => ('No Driver', const Color(0xFF6B7280)),
      TripStatus.declined => ('Declined', const Color(0xFFF59E0B)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
