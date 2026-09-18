import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:driveops_management/shared/models/route_point.dart';

/// OSM map for a trip: polyline route, green pickup marker, red dropoff
/// marker, and an optional blue marker at the assigned driver's last known
/// position.
class TripMapView extends StatelessWidget {
  final double pickupLatitude;
  final double pickupLongitude;
  final double dropoffLatitude;
  final double dropoffLongitude;
  final List<RoutePoint> routePoints;
  final LatLng? driverPosition;

  const TripMapView({
    super.key,
    required this.pickupLatitude,
    required this.pickupLongitude,
    required this.dropoffLatitude,
    required this.dropoffLongitude,
    required this.routePoints,
    this.driverPosition,
  });

  @override
  Widget build(BuildContext context) {
    final pickup = LatLng(pickupLatitude, pickupLongitude);
    final dropoff = LatLng(dropoffLatitude, dropoffLongitude);

    final polylinePoints = routePoints.length >= 2
        ? routePoints.map((p) => LatLng(p.latitude, p.longitude)).toList()
        : [pickup, dropoff];

    final bounds = LatLngBounds.fromPoints([
      pickup,
      dropoff,
      ...polylinePoints,
      ?driverPosition,
    ]);

    return FlutterMap(
      options: MapOptions(
        initialCameraFit: CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(32),
          maxZoom: 15,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.driveops.management',
        ),
        PolylineLayer(
          polylines: [
            Polyline(
              points: polylinePoints,
              color: const Color(0xFF3B82F6),
              strokeWidth: 3,
            ),
          ],
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: pickup,
              width: 28,
              height: 28,
              child: const Icon(Icons.trip_origin, color: Color(0xFF22C55E), size: 22),
            ),
            Marker(
              point: dropoff,
              width: 28,
              height: 28,
              child: const Icon(Icons.location_on, color: Color(0xFFEF4444), size: 26),
            ),
            if (driverPosition != null)
              Marker(
                point: driverPosition!,
                width: 28,
                height: 28,
                child: const Icon(Icons.directions_car, color: Color(0xFF3B82F6), size: 24),
              ),
          ],
        ),
      ],
    );
  }
}
