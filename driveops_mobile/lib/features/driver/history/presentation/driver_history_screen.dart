import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driveops_mobile/features/driver/history/presentation/trip_details_screen.dart';
import 'package:driveops_mobile/features/driver/history/presentation/widgets/trip_filter_dialog.dart';
import 'package:driveops_mobile/features/driver/history/presentation/widgets/trip_list_tile.dart';
import 'package:driveops_mobile/shared/models/trip.dart';
import 'package:driveops_mobile/shared/providers/repository_providers.dart';

/// Client-side filter state for the history list.
class TripFilter {
  final TripStatus? status;
  final DateTime? from;
  final DateTime? to;
  final String query;

  const TripFilter({this.status, this.from, this.to, this.query = ''});

  bool get isActive =>
      status != null || from != null || to != null || query.isNotEmpty;

  TripFilter copyWith({
    TripStatus? Function()? status,
    DateTime? Function()? from,
    DateTime? Function()? to,
    String? query,
  }) {
    return TripFilter(
      status: status != null ? status() : this.status,
      from: from != null ? from() : this.from,
      to: to != null ? to() : this.to,
      query: query ?? this.query,
    );
  }

  bool matches(Trip t) {
    if (status != null && t.tripStatus != status) return false;
    final requested = t.requestedAt;
    if (from != null && requested.isBefore(from!)) return false;
    if (to != null && requested.isAfter(to!.add(const Duration(days: 1)))) {
      return false;
    }
    if (query.isNotEmpty) {
      final q = query.toLowerCase();
      final haystack = '${t.pickupAddress} ${t.dropoffAddress} '
              '${t.customerName ?? ''}'
          .toLowerCase();
      if (!haystack.contains(q)) return false;
    }
    return true;
  }
}

class TripFilterNotifier extends Notifier<TripFilter> {
  @override
  TripFilter build() => const TripFilter();

  void setFilter(TripFilter filter) => state = filter;
}

final tripFilterProvider =
    NotifierProvider<TripFilterNotifier, TripFilter>(TripFilterNotifier.new);

class DriverHistoryScreen extends ConsumerWidget {
  const DriverHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsAsync = ref.watch(driverTripsProvider);
    final filter = ref.watch(tripFilterProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Trip History'),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: filter.isActive,
              child: const Icon(Icons.filter_list),
            ),
            tooltip: 'Filter trips',
            onPressed: () async {
              final result = await showDialog<TripFilter>(
                context: context,
                builder: (_) => TripFilterDialog(current: filter),
              );
              if (result != null) {
                ref.read(tripFilterProvider.notifier).setFilter(result);
              }
            },
          ),
        ],
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
                    color: Color(0xFFEF4444), size: 48),
                const SizedBox(height: 16),
                Text(
                  'Failed to load trips: $e',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(driverTripsProvider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (trips) {
          final filtered = trips.where(filter.matches).toList();

          if (filtered.isEmpty) {
            return Center(
              child: Text(
                filter.isActive
                    ? 'No trips match the current filters.'
                    : 'No trips yet.',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(driverTripsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: filtered.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final trip = filtered[index];
                return TripListTile(
                  trip: trip,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => TripDetailsScreen(trip: trip),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
