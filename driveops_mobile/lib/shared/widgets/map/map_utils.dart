import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Camera fit conventions shared with the management app (trip_map_view.dart).
CameraFit fitMapBounds(List<LatLng> points) {
  final bounds = LatLngBounds.fromPoints(points);
  return CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(32), maxZoom: 15);
}

/// Great-circle distance in meters between two coordinates.
double haversineMeters(LatLng a, LatLng b) =>
    const Distance().as(LengthUnit.Meter, a, b);
