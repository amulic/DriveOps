import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Role-agnostic base map for DriveOps (driver + customer).
///
/// Uses OpenStreetMap tiles — same stack and conventions as the management
/// app's trip map. Role-specific content is supplied via [layers].
class DriveOpsMap extends StatelessWidget {
  /// Initial camera position when no [initialFit] is given.
  final LatLng? initialCenter;
  final double initialZoom;

  /// One-shot camera fit applied at build time (e.g. trip bounds).
  final CameraFit? initialFit;

  /// Extra layers stacked above the tile layer (polylines, markers, circles).
  final List<Widget> layers;

  final MapController? mapController;
  final void Function(TapPosition, LatLng)? onTap;
  final void Function(TapPosition, LatLng)? onLongPress;

  const DriveOpsMap({
    super.key,
    this.initialCenter,
    this.initialZoom = 15,
    this.initialFit,
    this.layers = const [],
    this.mapController,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: initialCenter ?? const LatLng(0, 0),
        initialZoom: initialZoom,
        initialCameraFit: initialFit,
        onTap: onTap,
        onLongPress: onLongPress,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.driveops.mobile',
        ),
        ...layers,
        const RichAttributionWidget(
          attributions: [TextSourceAttribution('OpenStreetMap contributors')],
        ),
      ],
    );
  }
}
