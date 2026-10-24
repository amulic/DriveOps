import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Marker builders shared by the driver and customer maps.
///
/// Color vocabulary matches the management app's trip map:
/// blue `#3B82F6` driver/route, green `#22C55E` pickup, red `#EF4444` dropoff.

/// The device user's own live position (blue dot with a white halo).
Marker currentLocationMarker(LatLng point) {
  return Marker(
    point: point,
    width: 26,
    height: 26,
    child: Container(
      decoration: BoxDecoration(
        color: const Color(0xFF3B82F6),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
    ),
  );
}

/// A driver's position as seen by someone else (e.g. customer tracking).
Marker driverMarker(LatLng point) {
  return Marker(
    point: point,
    width: 32,
    height: 32,
    child: const Icon(Icons.directions_car, color: Color(0xFF3B82F6), size: 28),
  );
}

/// Trip pickup location.
Marker pickupMarker(LatLng point) {
  return Marker(
    point: point,
    width: 28,
    height: 28,
    child: const Icon(Icons.trip_origin, color: Color(0xFF22C55E), size: 22),
  );
}

/// Trip dropoff / destination location.
Marker dropoffMarker(LatLng point) {
  return Marker(
    point: point,
    width: 28,
    height: 28,
    child: const Icon(Icons.location_on, color: Color(0xFFEF4444), size: 26),
  );
}

/// Translucent accuracy halo for the current-location dot.
CircleMarker currentLocationAccuracyCircle(LatLng point, double radiusMeters) {
  return CircleMarker(
    point: point,
    radius: radiusMeters.clamp(10, 200),
    useRadiusInMeter: true,
    color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
    borderColor: const Color(0xFF3B82F6).withValues(alpha: 0.3),
    borderStrokeWidth: 1,
  );
}
