enum DriverStatus {
  pending,
  active,
  inactive,
  suspended,
  onTrip;

  static DriverStatus fromInt(int value) {
    if (value >= 0 && value < values.length) {
      return values[value];
    }
    return pending;
  }

  int toInt() => index;
}

class Driver {
  final String id;
  final String userId;
  final String driverName;
  final String email;
  final String phoneNumber;
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
  final DateTime? createdAt;
  final double activeTimeHours;

  const Driver({
    required this.id,
    required this.userId,
    required this.driverName,
    required this.email,
    required this.phoneNumber,
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
    this.createdAt,
    this.activeTimeHours = 0.0,
  });

  String get fullName => driverName;

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['id'] as String,
      userId: json['userId'] as String,
      driverName: json['driverName'] as String,
      email: json['email'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      licenseNumber: json['licenseNumber'] as String,
      licenseExpiryDate: DateTime.parse(json['licenseExpiryDate'] as String),
      status: DriverStatus.fromInt(json['status'] as int),
      rating: (json['rating'] as num).toDouble(),
      totalTrips: json['totalTrips'] as int,
      totalRevenue: (json['totalRevenue'] as num).toDouble(),
      currentLatitude: (json['currentLatitude'] as num?)?.toDouble(),
      currentLongitude: (json['currentLongitude'] as num?)?.toDouble(),
      isOnline: json['isOnline'] as bool? ?? false,
      emergencyContactName: json['emergencyContactName'] as String?,
      emergencyContactPhone: json['emergencyContactPhone'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'driverName': driverName,
      'email': email,
      'phoneNumber': phoneNumber,
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
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  Driver copyWith({
    String? id,
    String? userId,
    String? driverName,
    String? email,
    String? phoneNumber,
    String? licenseNumber,
    DateTime? licenseExpiryDate,
    DriverStatus? status,
    double? rating,
    int? totalTrips,
    double? totalRevenue,
    double? currentLatitude,
    double? currentLongitude,
    bool? isOnline,
    String? emergencyContactName,
    String? emergencyContactPhone,
    DateTime? createdAt,
    double? activeTimeHours,
  }) {
    return Driver(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      driverName: driverName ?? this.driverName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      licenseExpiryDate: licenseExpiryDate ?? this.licenseExpiryDate,
      status: status ?? this.status,
      rating: rating ?? this.rating,
      totalTrips: totalTrips ?? this.totalTrips,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      currentLatitude: currentLatitude ?? this.currentLatitude,
      currentLongitude: currentLongitude ?? this.currentLongitude,
      isOnline: isOnline ?? this.isOnline,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
      createdAt: createdAt ?? this.createdAt,
      activeTimeHours: activeTimeHours ?? this.activeTimeHours,
    );
  }
}