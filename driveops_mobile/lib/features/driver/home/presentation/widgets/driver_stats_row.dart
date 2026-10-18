import 'package:flutter/material.dart';
import 'package:driveops_mobile/shared/models/driver.dart';

/// Three stat cards: trips completed, rating, total earned.
class DriverStatsRow extends StatelessWidget {
  final Driver driver;

  const DriverStatsRow({super.key, required this.driver});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.check_circle_outline,
            iconColor: const Color(0xFF22C55E),
            value: '${driver.totalTrips}',
            label: 'Trips',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.star_outline,
            iconColor: const Color(0xFFF59E0B),
            value: driver.rating.toStringAsFixed(2),
            label: 'Rating',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.payments_outlined,
            iconColor: const Color(0xFF3B82F6),
            value: '\$${driver.totalRevenue.toStringAsFixed(0)}',
            label: 'Earned',
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
