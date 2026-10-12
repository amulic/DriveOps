import 'package:geolocator/geolocator.dart';

/// Outcome of the location permission/service checks.
enum LocationPermissionState { granted, serviceDisabled, denied, deniedForever }

/// Thrown when GPS data cannot be produced because of permissions/services.
class LocationPermissionException implements Exception {
  final LocationPermissionState state;
  const LocationPermissionException(this.state);

  @override
  String toString() => 'LocationPermissionException($state)';
}

/// Thin wrapper over geolocator, shared by the driver and customer apps.
class LocationService {
  /// Checks the location service and runtime permission, requesting the
  /// permission if needed. Does not throw — inspect the returned state.
  Future<LocationPermissionState> ensurePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return LocationPermissionState.serviceDisabled;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return switch (permission) {
      LocationPermission.denied => LocationPermissionState.denied,
      LocationPermission.deniedForever =>
        LocationPermissionState.deniedForever,
      _ => LocationPermissionState.granted,
    };
  }

  Future<Position> currentPosition() {
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }

  /// Continuous fixes; emits only after moving [distanceFilter] meters.
  Stream<Position> positionStream({int distanceFilter = 25}) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilter,
      ),
    );
  }

  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();
  Future<bool> openAppSettings() => Geolocator.openAppSettings();
}
