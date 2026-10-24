import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driveops_mobile/features/driver/providers/driver_providers.dart';

/// Pie chart of the driver's trips split into completed / cancelled / declined.
class TripsPieChart extends ConsumerWidget {
  const TripsPieChart({super.key});

  static const _completedColor = Color(0xFF22C55E);
  static const _cancelledColor = Color(0xFFEF4444);
  static const _declinedColor = Color(0xFFF59E0B);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(driverTripStatsProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Trip Breakdown',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          statsAsync.when(
            loading: () => const SizedBox(
              height: 180,
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
              ),
            ),
            error: (e, _) => SizedBox(
              height: 180,
              child: Center(
                child: Text(
                  'Could not load stats',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                ),
              ),
            ),
            data: (stats) {
              if (stats.total == 0) {
                return SizedBox(
                  height: 180,
                  child: Center(
                    child: Text(
                      'No trips yet',
                      style:
                          TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                    ),
                  ),
                );
              }

              return Column(
                children: [
                  SizedBox(
                    height: 180,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: [
                          _section('Completed', stats.completed, _completedColor),
                          _section('Cancelled', stats.cancelled, _cancelledColor),
                          _section('Declined', stats.declined, _declinedColor),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _legend('Completed', stats.completed, _completedColor),
                      _legend('Cancelled', stats.cancelled, _cancelledColor),
                      _legend('Declined', stats.declined, _declinedColor),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  PieChartSectionData _section(String label, int count, Color color) {
    return PieChartSectionData(
      value: count.toDouble(),
      color: color,
      radius: 50,
      title: count > 0 ? '$count' : '',
      titleStyle: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _legend(String label, int count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$label ($count)',
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}
