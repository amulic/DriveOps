import 'package:driveops_mobile/shared/models/route_point.dart';

class CreateTripRequest {
  final String customerId;
  final int tripType;
  final double pickupLatitude;
  final double pickupLongitude;
  final String pickupAddress;
  final double dropoffLatitude;
  final double dropoffLongitude;
  final String dropoffAddress;
  final DateTime? scheduledAt;
  final int? paymentMethod;
  final String? specialInstructions;

  const CreateTripRequest({
    required this.customerId,
    required this.tripType,
    required this.pickupLatitude,
    required this.pickupLongitude,
    required this.pickupAddress,
    required this.dropoffLatitude,
    required this.dropoffLongitude,
    required this.dropoffAddress,
    this.scheduledAt,
    this.paymentMethod,
    this.specialInstructions,
  });

  Map<String, dynamic> toJson() {
    return {
      'customerId': customerId,
      'tripType': tripType,
      'pickupLatitude': pickupLatitude,
      'pickupLongitude': pickupLongitude,
      'pickupAddress': pickupAddress,
      'dropoffLatitude': dropoffLatitude,
      'dropoffLongitude': dropoffLongitude,
      'dropoffAddress': dropoffAddress,
      if (scheduledAt != null) 'scheduledAt': scheduledAt!.toIso8601String(),
      if (paymentMethod != null) 'paymentMethod': paymentMethod,
      if (specialInstructions != null) 'specialInstructions': specialInstructions,
    };
  }
}

class TripEstimateRequest {
  final double pickupLatitude;
  final double pickupLongitude;
  final double dropoffLatitude;
  final double dropoffLongitude;
  final int tripType;

  const TripEstimateRequest({
    required this.pickupLatitude,
    required this.pickupLongitude,
    required this.dropoffLatitude,
    required this.dropoffLongitude,
    required this.tripType,
  });

  Map<String, dynamic> toJson() {
    return {
      'pickupLatitude': pickupLatitude,
      'pickupLongitude': pickupLongitude,
      'dropoffLatitude': dropoffLatitude,
      'dropoffLongitude': dropoffLongitude,
      'tripType': tripType,
    };
  }
}

class TripEstimateResponse {
  final double distanceKm;
  final int durationMinutes;
  final double estimatedFare;
  final List<RoutePoint> routePoints;

  TripEstimateResponse({
    required this.distanceKm,
    required this.durationMinutes,
    required this.estimatedFare,
    this.routePoints = const [],
  });

  factory TripEstimateResponse.fromJson(Map<String, dynamic> json) {
    return TripEstimateResponse(
      distanceKm: (json['distanceKm'] as num).toDouble(),
      durationMinutes: json['durationMinutes'] as int,
      estimatedFare: (json['estimatedFare'] as num).toDouble(),
      routePoints: (json['routePoints'] as List<dynamic>?)
              ?.map((e) => RoutePoint.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}

class AssignDriverRequest {
  final String driverId;
  final String vehicleId;

  const AssignDriverRequest({
    required this.driverId,
    required this.vehicleId,
  });

  Map<String, dynamic> toJson() {
    return {
      'driverId': driverId,
      'vehicleId': vehicleId,
    };
  }
}

class CompleteTripRequest {
  final double actualDistance;

  const CompleteTripRequest({required this.actualDistance});

  Map<String, dynamic> toJson() => {'actualDistance': actualDistance};
}

class CancelTripRequest {
  final String? reason;

  const CancelTripRequest({this.reason});

  Map<String, dynamic> toJson() => {'reason': reason};
}

class DeclineTripRequest {
  final String driverId;
  final String? reason;

  const DeclineTripRequest({required this.driverId, this.reason});

  Map<String, dynamic> toJson() => {
        'driverId': driverId,
        if (reason != null) 'reason': reason,
      };
}

class RateTripRequest {
  final int rating;
  final String? feedback;
  final bool isCustomerRating;

  const RateTripRequest({
    required this.rating,
    this.feedback,
    required this.isCustomerRating,
  });

  Map<String, dynamic> toJson() {
    return {
      'rating': rating,
      if (feedback != null) 'feedback': feedback,
      'isCustomerRating': isCustomerRating,
    };
  }
}