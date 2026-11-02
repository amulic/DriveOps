import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driveops_management/shared/models/recommended_driver.dart';
import 'package:driveops_management/shared/models/trip.dart';
import 'package:driveops_management/shared/providers/repository_providers.dart';
import 'package:driveops_management/features/trips/presentation/providers/trips_providers.dart';

/// Ranked recommended-driver cards with one-click assign.
class RecommendedDriversSection extends ConsumerStatefulWidget {
  final Trip trip;

  const RecommendedDriversSection({super.key, required this.trip});

  @override
  ConsumerState<RecommendedDriversSection> createState() => _RecommendedDriversSectionState();
}

class _RecommendedDriversSectionState extends ConsumerState<RecommendedDriversSection> {
  String? _assigningDriverId;

  Future<void> _assign(RecommendedDriver driver) async {
    setState(() => _assigningDriverId = driver.driverId);
    try {
      await ref.read(tripRepositoryProvider).assignDriver(
            widget.trip.id,
            driver.driverId,
            driver.vehicleId!,
          );
      ref.invalidate(tripsAsyncProvider);
      ref.invalidate(tripsDriversAsyncProvider);
      ref.invalidate(recommendedDriversProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${driver.driverName} assigned to trip')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to assign driver: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _assigningDriverId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final recommendationsAsync = ref.watch(recommendedDriversProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recommended Drivers',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        recommendationsAsync.when(
          data: (drivers) {
            if (drivers.isEmpty) {
              return const Text(
                'No available drivers nearby.',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              );
            }
            return Column(
              children: [
                for (var i = 0; i < drivers.length; i++)
                  _DriverCard(
                    driver: drivers[i],
                    position: i + 1,
                    isAssigning: _assigningDriverId == drivers[i].driverId,
                    onAssign: () => _assign(drivers[i]),
                  ),
              ],
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
            ),
          ),
          error: (error, _) => Text(
            'Failed to load recommendations: $error',
            style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13),
          ),
        ),
      ],
    );
  }
}

class _DriverCard extends StatelessWidget {
  final RecommendedDriver driver;
  final int position;
  final bool isAssigning;
  final VoidCallback onAssign;

  const _DriverCard({
    required this.driver,
    required this.position,
    required this.isAssigning,
    required this.onAssign,
  });

  @override
  Widget build(BuildContext context) {
    final hasVehicle = driver.vehicleId != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF252538),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Text(
              '$position',
              style: const TextStyle(
                color: Color(0xFF3B82F6),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  driver.driverName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Wrap(
                  spacing: 8,
                  children: [
                    _meta(Icons.star, (driver.rating ?? 5.0).toStringAsFixed(1)),
                    if (driver.distanceKm != null)
                      _meta(Icons.near_me, '${driver.distanceKm!.toStringAsFixed(1)} km'),
                    if (driver.totalTrips != null)
                      _meta(Icons.route, '${driver.totalTrips} trips'),
                    if (driver.vehiclePlate != null)
                      _meta(Icons.directions_car, driver.vehiclePlate!),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _explain(driver),
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: driver.score.clamp(0.0, 1.0),
                    minHeight: 3,
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF3B82F6)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Tooltip(
            message: hasVehicle ? '' : 'No available vehicle',
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: const Size(0, 32),
              ),
              onPressed: hasVehicle && !isAssigning ? onAssign : null,
              child: isAssigning
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Assign', style: TextStyle(fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  /// Explainable recommendation: shows the score components behind the rank.
  String _explain(RecommendedDriver d) {
    final proximity = d.distanceScore != null
        ? '${(d.distanceScore! * 100).round()}% proximity '
            '(${d.distanceKm!.toStringAsFixed(1)} km)'
        : 'no GPS';
    final rating = '${((d.ratingScore ?? 0) * 100).round()}% rating '
        '(${(d.rating ?? 5).toStringAsFixed(1)}★)';
    return 'Why: $proximity · $rating → score ${d.score.toStringAsFixed(2)}';
  }

  Widget _meta(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white54, size: 12),
        const SizedBox(width: 2),
        Text(text, style: const TextStyle(color: Colors.white54, fontSize: 11)),
      ],
    );
  }
}
