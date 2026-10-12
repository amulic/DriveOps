import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:driveops_mobile/shared/models/route_point.dart';

/// Blue route polyline shared by driver/customer maps.
///
/// Falls back to a straight line between [fallbackStart] and [fallbackEnd]
/// when fewer than 2 route points are available (management app convention).
PolylineLayer routePolylineLayer(
  List<RoutePoint> routePoints, {
  LatLng? fallbackStart,
  LatLng? fallbackEnd,
}) {
  final points = routePoints.length >= 2
      ? routePoints.map((p) => LatLng(p.latitude, p.longitude)).toList()
      : [?fallbackStart, ?fallbackEnd];

  return PolylineLayer(
    polylines: [
      if (points.length >= 2)
        Polyline(points: points, color: const Color(0xFF3B82F6), strokeWidth: 3),
    ],
  );
}
