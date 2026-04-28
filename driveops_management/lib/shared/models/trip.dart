enum TripStatus {
  requested,
  assigned,
  driverEnRoute,
  inProgress,
  completed,
  cancelled,
  noDriverAvailable;

  static TripStatus fromInt(int value) {
    if (value >= 0 && value < values.length) {
      return values[value];
    }
    return requested;
  }

  int toInt() => index;
}

enum TripType {
  standard,
  premium;

  static TripType fromInt(int value) {
    return TripType.values[value];
  }

  int toInt() => index;
}

class Trip {
  final String id;
  final String customerId;
  final String? driverId;
  final String? vehicleId;
  final TripStatus tripStatus;
  final TripType tripType;
  final String pickupAddress;
  final String dropoffAddress;
  final double? estimatedFare;
  final double? actualFare;
  final DateTime requestedAt;
  final DateTime? pickupTime;
  final DateTime? dropoffTime;
  final String? cancellationReason;

  const Trip({
    required this.id,
    required this.customerId,
    this.driverId,
    this.vehicleId,
    required this.tripStatus,
    required this.tripType,
    required this.pickupAddress,
    required this.dropoffAddress,
    this.estimatedFare,
    this.actualFare,
    required this.requestedAt,
    this.pickupTime,
    this.dropoffTime,
    this.cancellationReason,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'] as String,
      customerId: json['customerId'] as String,
      driverId: json['driverId'] as String?,
      vehicleId: json['vehicleId'] as String?,
      tripStatus: TripStatus.fromInt(json['tripStatus'] as int),
      tripType: TripType.fromInt(json['tripType'] as int),
      pickupAddress: json['pickupAddress'] as String,
      dropoffAddress: json['dropoffAddress'] as String,
      estimatedFare: (json['estimatedFare'] as num?)?.toDouble(),
      actualFare: (json['actualFare'] as num?)?.toDouble(),
      requestedAt: DateTime.parse(json['requestedAt'] as String),
      pickupTime: json['pickupTime'] != null
          ? DateTime.parse(json['pickupTime'] as String)
          : null,
      dropoffTime: json['dropoffTime'] != null
          ? DateTime.parse(json['dropoffTime'] as String)
          : null,
      cancellationReason: json['cancellationReason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'driverId': driverId,
      'vehicleId': vehicleId,
      'tripStatus': tripStatus.toInt(),
      'tripType': tripType.toInt(),
      'pickupAddress': pickupAddress,
      'dropoffAddress': dropoffAddress,
      'estimatedFare': estimatedFare,
      'actualFare': actualFare,
      'requestedAt': requestedAt.toIso8601String(),
      'pickupTime': pickupTime?.toIso8601String(),
      'dropoffTime': dropoffTime?.toIso8601String(),
      'cancellationReason': cancellationReason,
    };
  }
}
