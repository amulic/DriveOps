import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/trip.dart';
import '../providers/dashboard_providers.dart';

class RecentRidesTable extends ConsumerWidget {
  const RecentRidesTable({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsData = ref.watch(tripsProvider);
    final recentTrips = tripsData.recent.take(10).toList();

    return Card(
      color: const Color(0xFF252538),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Rides',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 24,
                columns: const [
                  DataColumn(label: Text('Trip ID')),
                  DataColumn(label: Text('Pickup → Dropoff')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Fare')),
                  DataColumn(label: Text('Date')),
                ],
                rows: recentTrips.map((trip) {
                  return DataRow(
                    cells: [
                      DataCell(
                        Text(
                          '#${trip.id.substring(trip.id.length - 4)}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 220,
                          child: Text(
                            '${trip.pickupAddress.split(',').first} → ${trip.dropoffAddress.split(',').first}',
                            style: const TextStyle(color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataCell(_buildStatusChip(trip.tripStatus)),
                      DataCell(
                        Text(
                          trip.actualFare != null
                              ? '\$${trip.actualFare!.toStringAsFixed(2)}'
                              : trip.estimatedFare != null
                                  ? '\$${trip.estimatedFare!.toStringAsFixed(2)}*'
                                  : '-',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      DataCell(
                        Text(
                          _formatDate(trip.requestedAt),
                          style: const TextStyle(color: Colors.white54),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(TripStatus status) {
    Color color;
    String label;

    switch (status) {
      case TripStatus.completed:
        color = const Color(0xFF22C55E);
        label = 'Completed';
        break;
      case TripStatus.cancelled:
        color = const Color(0xFFEF4444);
        label = 'Cancelled';
        break;
      case TripStatus.noDriverAvailable:
        color = const Color(0xFFF59E0B);
        label = 'No Driver';
        break;
      case TripStatus.inProgress:
        color = const Color(0xFF3B82F6);
        label = 'In Progress';
        break;
      case TripStatus.driverEnRoute:
        color = const Color(0xFF8B5CF6);
        label = 'En Route';
        break;
      case TripStatus.assigned:
        color = const Color(0xFF06B6D4);
        label = 'Assigned';
        break;
      default:
        color = Colors.grey;
        label = 'Requested';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }
}
