enum TripStatus {
  requested,
  assigned,
  driverEnRoute,
  inProgress,
  completed,
  cancelled,
  noDriverAvailable,
  declined;

  static TripStatus fromInt(int value) {
    if (value >= 1 && value <= values.length) {
      return values[value - 1];
    }
    return requested;
  }

  int toInt() => index + 1;
}

enum TripType {
  standard,
  premium,
  shared;

  static TripType fromInt(int value) {
    if (value >= 0 && value < values.length) {
      return values[value - 1];
    }
    return standard;
  }

  int toInt() => index + 1;
}

enum PaymentMethod {
  cash,
  creditCard,
  debitCard,
  digitalWallet;

  static PaymentMethod fromInt(int value) {
    if (value >= 0 && value < values.length) {
      return values[value - 1];
    }
    return cash;
  }

  int toInt() => index + 1;
}

enum PaymentStatus {
  pending,
  completed,
  failed,
  refunded;

  static PaymentStatus fromInt(int value) {
    if (value >= 0 && value < values.length) {
      return values[value - 1];
    }
    return pending;
  }

  int toInt() => index + 1;
}

class Trip {
  final String id;
  final String customerId;
  final String? customerName;
  final String? driverId;
  final String? driverName;
  final String? vehicleId;
  final String? vehiclePlate;
  final TripStatus tripStatus;
  final TripType tripType;
  final double pickupLatitude;
  final double pickupLongitude;
  final String pickupAddress;
  final double dropoffLatitude;
  final double dropoffLongitude;
  final String dropoffAddress;
  final DateTime requestedAt;
  final DateTime? assignedAt;
  final DateTime? pickupTime;
  final DateTime? dropoffTime;
  final double? estimatedDistance;
  final double? actualDistance;
  final int? estimatedDuration;
  final int? actualDuration;
  final double? estimatedFare;
  final double? actualFare;
  final PaymentMethod? paymentMethod;
  final PaymentStatus? paymentStatus;
  final int? customerRating;
  final int? driverRating;
  final String? cancellationReason;
  final String? specialInstructions;
  final DateTime? createdAt;

  const Trip({
    required this.id,
    required this.customerId,
    this.customerName,
    this.driverId,
    this.driverName,
    this.vehicleId,
    this.vehiclePlate,
    required this.tripStatus,
    required this.tripType,
    required this.pickupLatitude,
    required this.pickupLongitude,
    required this.pickupAddress,
    required this.dropoffLatitude,
    required this.dropoffLongitude,
    required this.dropoffAddress,
    required this.requestedAt,
    this.assignedAt,
    this.pickupTime,
    this.dropoffTime,
    this.estimatedDistance,
    this.actualDistance,
    this.estimatedDuration,
    this.actualDuration,
    this.estimatedFare,
    this.actualFare,
    this.paymentMethod,
    this.paymentStatus,
    this.customerRating,
    this.driverRating,
    this.cancellationReason,
    this.specialInstructions,
    this.createdAt,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'] as String,
      customerId: json['customerId'] as String,
      customerName: json['customerName'] as String?,
      driverId: json['driverId'] as String?,
      driverName: json['driverName'] as String?,
      vehicleId: json['vehicleId'] as String?,
      vehiclePlate: json['vehiclePlate'] as String?,
      tripStatus: TripStatus.fromInt(json['tripStatus'] as int),
      tripType: TripType.fromInt(json['tripType'] as int),
      pickupLatitude: (json['pickupLatitude'] as num).toDouble(),
      pickupLongitude: (json['pickupLongitude'] as num).toDouble(),
      pickupAddress: json['pickupAddress'] as String,
      dropoffLatitude: (json['dropoffLatitude'] as num).toDouble(),
      dropoffLongitude: (json['dropoffLongitude'] as num).toDouble(),
      dropoffAddress: json['dropoffAddress'] as String,
      requestedAt: DateTime.parse(json['requestedAt'] as String),
      assignedAt: json['assignedAt'] != null
          ? DateTime.parse(json['assignedAt'] as String)
          : null,
      pickupTime: json['pickupTime'] != null
          ? DateTime.parse(json['pickupTime'] as String)
          : null,
      dropoffTime: json['dropoffTime'] != null
          ? DateTime.parse(json['dropoffTime'] as String)
          : null,
      estimatedDistance: (json['estimatedDistance'] as num?)?.toDouble(),
      actualDistance: (json['actualDistance'] as num?)?.toDouble(),
      estimatedDuration: json['estimatedDuration'] as int?,
      actualDuration: json['actualDuration'] as int?,
      estimatedFare: (json['estimatedFare'] as num?)?.toDouble(),
      actualFare: (json['actualFare'] as num?)?.toDouble(),
      paymentMethod: json['paymentMethod'] != null
          ? PaymentMethod.fromInt(json['paymentMethod'] as int)
          : null,
      paymentStatus: json['paymentStatus'] != null
          ? PaymentStatus.fromInt(json['paymentStatus'] as int)
          : null,
      customerRating: json['customerRating'] as int?,
      driverRating: json['driverRating'] as int?,
      cancellationReason: json['cancellationReason'] as String?,
      specialInstructions: json['specialInstructions'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'customerName': customerName,
      'driverId': driverId,
      'driverName': driverName,
      'vehicleId': vehicleId,
      'vehiclePlate': vehiclePlate,
      'tripStatus': tripStatus.toInt(),
      'tripType': tripType.toInt(),
      'pickupLatitude': pickupLatitude,
      'pickupLongitude': pickupLongitude,
      'pickupAddress': pickupAddress,
      'dropoffLatitude': dropoffLatitude,
      'dropoffLongitude': dropoffLongitude,
      'dropoffAddress': dropoffAddress,
      'requestedAt': requestedAt.toIso8601String(),
      'assignedAt': assignedAt?.toIso8601String(),
      'pickupTime': pickupTime?.toIso8601String(),
      'dropoffTime': dropoffTime?.toIso8601String(),
      'estimatedDistance': estimatedDistance,
      'actualDistance': actualDistance,
      'estimatedDuration': estimatedDuration,
      'actualDuration': actualDuration,
      'estimatedFare': estimatedFare,
      'actualFare': actualFare,
      'paymentMethod': paymentMethod?.toInt(),
      'paymentStatus': paymentStatus?.toInt(),
      'customerRating': customerRating,
      'driverRating': driverRating,
      'cancellationReason': cancellationReason,
      'specialInstructions': specialInstructions,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  Trip copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? driverId,
    String? driverName,
    String? vehicleId,
    String? vehiclePlate,
    TripStatus? tripStatus,
    TripType? tripType,
    double? pickupLatitude,
    double? pickupLongitude,
    String? pickupAddress,
    double? dropoffLatitude,
    double? dropoffLongitude,
    String? dropoffAddress,
    DateTime? requestedAt,
    DateTime? assignedAt,
    DateTime? pickupTime,
    DateTime? dropoffTime,
    double? estimatedDistance,
    double? actualDistance,
    int? estimatedDuration,
    int? actualDuration,
    double? estimatedFare,
    double? actualFare,
    PaymentMethod? paymentMethod,
    PaymentStatus? paymentStatus,
    int? customerRating,
    int? driverRating,
    String? cancellationReason,
    String? specialInstructions,
    DateTime? createdAt,
  }) {
    return Trip(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      vehicleId: vehicleId ?? this.vehicleId,
      vehiclePlate: vehiclePlate ?? this.vehiclePlate,
      tripStatus: tripStatus ?? this.tripStatus,
      tripType: tripType ?? this.tripType,
      pickupLatitude: pickupLatitude ?? this.pickupLatitude,
      pickupLongitude: pickupLongitude ?? this.pickupLongitude,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      dropoffLatitude: dropoffLatitude ?? this.dropoffLatitude,
      dropoffLongitude: dropoffLongitude ?? this.dropoffLongitude,
      dropoffAddress: dropoffAddress ?? this.dropoffAddress,
      requestedAt: requestedAt ?? this.requestedAt,
      assignedAt: assignedAt ?? this.assignedAt,
      pickupTime: pickupTime ?? this.pickupTime,
      dropoffTime: dropoffTime ?? this.dropoffTime,
      estimatedDistance: estimatedDistance ?? this.estimatedDistance,
      actualDistance: actualDistance ?? this.actualDistance,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      actualDuration: actualDuration ?? this.actualDuration,
      estimatedFare: estimatedFare ?? this.estimatedFare,
      actualFare: actualFare ?? this.actualFare,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      customerRating: customerRating ?? this.customerRating,
      driverRating: driverRating ?? this.driverRating,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}