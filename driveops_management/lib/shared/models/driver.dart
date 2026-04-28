enum DriverStatus {
  pending,
  active,
  inactive,
  suspended,
  onTrip;

  static DriverStatus fromInt(int value) {
    return DriverStatus.values[value];
  }

  int toInt() => index;
}

class Driver {
  final String id;
  final String userId;
  final String name;
  final String licenseNumber;
  final DateTime licenseExpiryDate;
  final DriverStatus status;
  final double rating;
  final int totalTrips;
  final double totalRevenue;
  final double? currentLatitude;
  final double? currentLongitude;
  final bool isOnline;
  final String? emergencyContactName;
  final String? emergencyContactPhone;

  const Driver({
    required this.id,
    required this.userId,
    required this.name,
    required this.licenseNumber,
    required this.licenseExpiryDate,
    required this.status,
    required this.rating,
    required this.totalTrips,
    required this.totalRevenue,
    this.currentLatitude,
    this.currentLongitude,
    required this.isOnline,
    this.emergencyContactName,
    this.emergencyContactPhone,
  });

  String get fullName => name;

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String? ?? '${json['firstName']} ${json['lastName']}',
      licenseNumber: json['licenseNumber'] as String,
      licenseExpiryDate: DateTime.parse(json['licenseExpiryDate'] as String),
      status: DriverStatus.fromInt(json['status'] as int),
      rating: (json['rating'] as num).toDouble(),
      totalTrips: json['totalTrips'] as int,
      totalRevenue: (json['totalRevenue'] as num).toDouble(),
      currentLatitude: (json['currentLatitude'] as num?)?.toDouble(),
      currentLongitude: (json['currentLongitude'] as num?)?.toDouble(),
      isOnline: json['isOnline'] as bool,
      emergencyContactName: json['emergencyContactName'] as String?,
      emergencyContactPhone: json['emergencyContactPhone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'licenseNumber': licenseNumber,
      'licenseExpiryDate': licenseExpiryDate.toIso8601String(),
      'status': status.toInt(),
      'rating': rating,
      'totalTrips': totalTrips,
      'totalRevenue': totalRevenue,
      'currentLatitude': currentLatitude,
      'currentLongitude': currentLongitude,
      'isOnline': isOnline,
      'emergencyContactName': emergencyContactName,
      'emergencyContactPhone': emergencyContactPhone,
    };
  }
}
