import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/repository_providers.dart';

class RideStatisticsChart extends ConsumerWidget {
  const RideStatisticsChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(tripStatisticsProvider);

    return Card(
      color: const Color(0xFF252538),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ride Statistics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            statsAsync.when(
              data: (stats) => _buildChart(stats),
              loading: () => const SizedBox(
                height: 180,
                child: Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6))),
              ),
              error: (_, __) => const SizedBox(
                height: 180,
                child: Center(child: Text('Failed to load', style: TextStyle(color: Colors.white54))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(Map<String, int> stats) {
    final completed = stats['completed'] ?? 0;
    final cancelled = stats['cancelled'] ?? 0;
    final noDriver = stats['noDriverAvailable'] ?? 0;
    final total = completed + cancelled + noDriver;

    final completedPercent = total > 0 ? (completed / total * 100) : 0.0;
    final cancelledPercent = total > 0 ? (cancelled / total * 100) : 0.0;
    final noDriverPercent = total > 0 ? (noDriver / total * 100) : 0.0;

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 50,
              sections: [
                PieChartSectionData(
                  value: completed.toDouble(),
                  color: const Color(0xFF22C55E),
                  title: '${completedPercent.toStringAsFixed(0)}%',
                  titleStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  radius: 50,
                ),
                PieChartSectionData(
                  value: cancelled.toDouble(),
                  color: const Color(0xFFEF4444),
                  title: '${cancelledPercent.toStringAsFixed(0)}%',
                  titleStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  radius: 50,
                ),
                PieChartSectionData(
                  value: noDriver.toDouble(),
                  color: const Color(0xFFF59E0B),
                  title: '${noDriverPercent.toStringAsFixed(0)}%',
                  titleStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  radius: 50,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildLegendItem('Completed', const Color(0xFF22C55E), completed),
            _buildLegendItem('Cancelled', const Color(0xFFEF4444), cancelled),
            _buildLegendItem('No Driver', const Color(0xFFF59E0B), noDriver),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color, int count) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          count.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}