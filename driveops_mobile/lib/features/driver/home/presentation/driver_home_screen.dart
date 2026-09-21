import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driveops_mobile/features/driver/home/presentation/widgets/driver_header.dart';
import 'package:driveops_mobile/features/driver/home/presentation/widgets/driver_stats_row.dart';
import 'package:driveops_mobile/features/driver/home/presentation/widgets/trips_pie_chart.dart';
import 'package:driveops_mobile/shared/providers/auth_provider.dart';
import 'package:driveops_mobile/shared/providers/repository_providers.dart';

class DriverHomeScreen extends ConsumerWidget {
  const DriverHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final driverAsync = ref.watch(currentDriverProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(currentDriverProvider);
          ref.invalidate(driverTripsProvider);
        },
        child: driverAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
          ),
          error: (e, _) => _ErrorState(
            message: 'Failed to load driver profile: $e',
            onRetry: () => ref.invalidate(currentDriverProvider),
          ),
          data: (driver) {
            if (driver == null) {
              return _ErrorState(
                message: 'No driver profile is linked to this account '
                    '(${user?.email ?? 'unknown'}). Ask your dispatcher to '
                    'create one.',
                onRetry: () => ref.invalidate(currentDriverProvider),
              );
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                DriverHeader(driver: driver),
                const SizedBox(height: 20),
                DriverStatsRow(driver: driver),
                const SizedBox(height: 20),
                const TripsPieChart(),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 120),
        const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 48),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ),
      ],
    );
  }
}
