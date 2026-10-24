class RoutePoint {
  final double latitude;
  final double longitude;
  final DateTime? timestamp;

  const RoutePoint({
    required this.latitude,
    required this.longitude,
    this.timestamp,
  });

  factory RoutePoint.fromJson(Map<String, dynamic> json) {
    return RoutePoint(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      if (timestamp != null) 'timestamp': timestamp!.toIso8601String(),
    };
  }
}
