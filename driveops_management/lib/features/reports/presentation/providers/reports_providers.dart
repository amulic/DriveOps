import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driveops_management/shared/models/driver.dart';
import 'package:driveops_management/shared/models/trip.dart';
import 'package:driveops_management/shared/providers/repository_providers.dart';

class ReportDateRangeNotifier extends Notifier<DateTimeRange?> {
  @override
  DateTimeRange? build() => null;

  void setRange(DateTimeRange? range) => state = range;
}

final reportDateRangeProvider =
    NotifierProvider<ReportDateRangeNotifier, DateTimeRange?>(
      ReportDateRangeNotifier.new,
    );

class DailyTripStats {
  final DateTime date;
  final int trips;
  final int completed;
  final double revenue;

  const DailyTripStats({
    required this.date,
    required this.trips,
    required this.completed,
    required this.revenue,
  });
}

class TripReportData {
  final DateTimeRange? range;
  final int totalTrips;
  final int completed;
  final int cancelled;
  final int noDriverAvailable;
  final double revenue;
  final List<DailyTripStats> daily;

  const TripReportData({
    required this.range,
    required this.totalTrips,
    required this.completed,
    required this.cancelled,
    required this.noDriverAvailable,
    required this.revenue,
    required this.daily,
  });
}

class _DailyAccumulator {
  int trips = 0;
  int completed = 0;
  double revenue = 0.0;
}

DateTime _startOfDay(DateTime date) =>
    DateTime(date.year, date.month, date.day);

DateTime _endOfDay(DateTime date) =>
    DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

final tripsReportProvider = FutureProvider<TripReportData>((ref) async {
  final trips = await ref.watch(allTripsProvider.future);
  final range = ref.watch(reportDateRangeProvider);

  final start = range == null ? null : _startOfDay(range.start);
  final end = range == null ? null : _endOfDay(range.end);

  bool inRange(DateTime date) {
    if (start == null || end == null) return true;
    return !date.isBefore(start) && !date.isAfter(end);
  }

  final filtered = trips.where((t) => inRange(t.requestedAt)).toList();
  final completedTrips = filtered
      .where((t) => t.tripStatus == TripStatus.completed)
      .toList();

  final revenue = completedTrips.fold<double>(
    0.0,
    (sum, t) => sum + (t.actualFare ?? t.estimatedFare ?? 0.0),
  );

  final dailyMap = <DateTime, _DailyAccumulator>{};
  for (final trip in filtered) {
    final day = _startOfDay(trip.requestedAt);
    final accumulator = dailyMap.putIfAbsent(day, () => _DailyAccumulator());
    accumulator.trips++;
    if (trip.tripStatus == TripStatus.completed) {
      accumulator.completed++;
      accumulator.revenue += trip.actualFare ?? trip.estimatedFare ?? 0.0;
    }
  }

  final daily =
      dailyMap.entries
          .map(
            (entry) => DailyTripStats(
              date: entry.key,
              trips: entry.value.trips,
              completed: entry.value.completed,
              revenue: entry.value.revenue,
            ),
          )
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  return TripReportData(
    range: range,
    totalTrips: filtered.length,
    completed: completedTrips.length,
    cancelled: filtered
        .where((t) => t.tripStatus == TripStatus.cancelled)
        .length,
    noDriverAvailable: filtered
        .where((t) => t.tripStatus == TripStatus.noDriverAvailable)
        .length,
    revenue: revenue,
    daily: daily,
  );
});

final driverScoreboardReportProvider = FutureProvider<List<Driver>>((
  ref,
) async {
  final drivers = await ref.watch(allDriversProvider.future);
  final sorted = List<Driver>.from(drivers)
    ..sort((a, b) {
      final ratingCompare = b.rating.compareTo(a.rating);
      if (ratingCompare != 0) return ratingCompare;
      return b.totalTrips.compareTo(a.totalTrips);
    });
  return sorted;
});
