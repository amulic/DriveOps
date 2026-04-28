import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/dashboard_providers.dart';
import 'widgets/stats_card.dart';
import 'widgets/recent_rides_table.dart';
import 'widgets/ride_statistics_chart.dart';
import 'widgets/vehicles_service_table.dart';
import 'widgets/driver_scoreboard.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final driversData = ref.watch(driversProvider);
    final vehiclesData = ref.watch(vehiclesProvider);
    final revenue = ref.watch(revenueProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dashboard',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Welcome back, Admin Manager',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white54,
              ),
            ),
            const SizedBox(height: 24),
            _buildStatsRow(driversData, vehiclesData, revenue),
            const SizedBox(height: 24),
            _buildChartsRow(),
            const SizedBox(height: 24),
            _buildBottomRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(DriversData driversData, VehiclesData vehiclesData, double revenue) {
    return Row(
      children: [
        Expanded(
          child: StatsCard(
            icon: Icons.people,
            title: 'Total Drivers',
            value: driversData.total.toString(),
            iconColor: const Color(0xFF3B82F6),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatsCard(
            icon: Icons.check_circle,
            title: 'Active Drivers',
            value: driversData.active.length.toString(),
            iconColor: const Color(0xFF22C55E),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatsCard(
            icon: Icons.directions_car,
            title: 'Total Vehicles',
            value: vehiclesData.total.toString(),
            iconColor: const Color(0xFFF59E0B),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatsCard(
            icon: Icons.attach_money,
            title: 'Total Revenue',
            value: '\$${(revenue / 1000).toStringAsFixed(1)}K',
            iconColor: const Color(0xFF22C55E),
          ),
        ),
      ],
    );
  }

  Widget _buildChartsRow() {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 2, child: RecentRidesTable()),
        SizedBox(width: 16),
        Expanded(child: RideStatisticsChart()),
      ],
    );
  }

  Widget _buildBottomRow() {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: VehiclesServiceTable()),
        SizedBox(width: 16),
        Expanded(child: DriverScoreboard()),
      ],
    );
  }
}
