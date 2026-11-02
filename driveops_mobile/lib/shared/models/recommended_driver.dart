class RecommendedDriver {
  final String driverId;
  final String driverName;
  final double? rating;
  final int? totalTrips;
  final double? currentLatitude;
  final double? currentLongitude;
  final double? distanceKm;
  final double? distanceScore;
  final double? ratingScore;
  final double score;
  final String? vehicleId;
  final String? vehiclePlate;

  const RecommendedDriver({
    required this.driverId,
    required this.driverName,
    this.rating,
    this.totalTrips,
    this.currentLatitude,
    this.currentLongitude,
    this.distanceKm,
    this.distanceScore,
    this.ratingScore,
    required this.score,
    this.vehicleId,
    this.vehiclePlate,
  });

  factory RecommendedDriver.fromJson(Map<String, dynamic> json) {
    return RecommendedDriver(
      driverId: json['driverId'] as String,
      driverName: json['driverName'] as String,
      rating: (json['rating'] as num?)?.toDouble(),
      totalTrips: json['totalTrips'] as int?,
      currentLatitude: (json['currentLatitude'] as num?)?.toDouble(),
      currentLongitude: (json['currentLongitude'] as num?)?.toDouble(),
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      distanceScore: (json['distanceScore'] as num?)?.toDouble(),
      ratingScore: (json['ratingScore'] as num?)?.toDouble(),
      score: (json['score'] as num).toDouble(),
      vehicleId: json['vehicleId'] as String?,
      vehiclePlate: json['vehiclePlate'] as String?,
    );
  }
}
