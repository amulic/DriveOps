import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:driveops_mobile/shared/location/location_service.dart';

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

/// The device user's position in a map-ready form.
class DevicePosition {
  final LatLng latLng;
  final double accuracyMeters;
  final DateTime timestamp;

  const DevicePosition({
    required this.latLng,
    required this.accuracyMeters,
    required this.timestamp,
  });
}

DevicePosition _toDevicePosition(Position p) => DevicePosition(
      latLng: LatLng(p.latitude, p.longitude),
      accuracyMeters: p.accuracy,
      timestamp: p.timestamp,
    );

/// Streams the device position (25 m distance filter).
///
/// autoDispose so the GPS radio turns off when no screen/provider listens.
/// Errors surface as [LocationPermissionException] in the AsyncValue.
final currentPositionProvider =
    StreamProvider.autoDispose<DevicePosition>((ref) async* {
  final service = ref.watch(locationServiceProvider);
  final state = await service.ensurePermission();
  if (state != LocationPermissionState.granted) {
    throw LocationPermissionException(state);
  }

  // Fast first fix so the map can center immediately.
  try {
    yield _toDevicePosition(await service.currentPosition());
  } catch (_) {
    // A stale/cold fix is fine to skip — the stream below keeps trying.
  }

  await for (final position in service.positionStream()) {
    yield _toDevicePosition(position);
  }
});
