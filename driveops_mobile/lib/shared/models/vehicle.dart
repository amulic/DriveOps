enum VehicleStatus {
  available,
  inUse,
  maintenance,
  retired;

  static VehicleStatus fromInt(int value) {
    if (value >= 0 && value < values.length) {
      return values[value - 1];
    }
    return available;
  }

  int toInt() => index + 1;
}

enum FuelType {
  petrol,
  diesel,
  hybrid,
  electric;

  static FuelType fromInt(int value) {
    if (value >= 0 && value < values.length) {
      return values[value];
    }
    return petrol;
  }

  int toInt() => index;
}

class Vehicle {
  final String id;
  final String licensePlate;
  final String make;
  final String model;
  final int year;
  final String color;
  final String vin;
  final String insurancePolicyNumber;
  final VehicleStatus status;
  final int? mileage;
  final FuelType fuelType;
  final int? seatingCapacity;
  final String? assignedDriverId;
  final String? assignedDriverName;
  final String? photoUrl;
  final String? internalName;
  final DateTime? lastServiceDate;
  final DateTime insuranceExpiryDate;
  final DateTime registrationExpiryDate;
  final DateTime? createdAt;

  const Vehicle({
    required this.id,
    required this.licensePlate,
    required this.make,
    required this.model,
    required this.year,
    required this.color,
    required this.vin,
    required this.insurancePolicyNumber,
    required this.status,
    this.mileage,
    required this.fuelType,
    this.seatingCapacity,
    this.assignedDriverId,
    this.assignedDriverName,
    this.photoUrl,
    this.internalName,
    this.lastServiceDate,
    required this.insuranceExpiryDate,
    required this.registrationExpiryDate,
    this.createdAt,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'] as String,
      licensePlate: json['licensePlate'] as String,
      make: json['make'] as String,
      model: json['model'] as String,
      year: json['year'] as int,
      color: json['color'] as String,
      vin: json['vin'] as String,
      insurancePolicyNumber: json['insurancePolicyNumber'] as String? ?? '',
      status: VehicleStatus.fromInt(json['status'] as int),
      mileage: json['mileage'] as int?,
      fuelType: FuelType.fromInt(json['fuelType'] as int),
      seatingCapacity: json['seatingCapacity'] as int?,
      assignedDriverId: json['assignedDriverId'] as String?,
      assignedDriverName: json['assignedDriverName'] as String?,
      photoUrl: json['photoUrl'] as String?,
      internalName: json['internalName'] as String?,
      lastServiceDate: json['lastServiceDate'] != null
          ? DateTime.parse(json['lastServiceDate'] as String)
          : null,
      insuranceExpiryDate:
          DateTime.parse(json['insuranceExpiryDate'] as String),
      registrationExpiryDate:
          DateTime.parse(json['registrationExpiryDate'] as String),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'licensePlate': licensePlate,
      'make': make,
      'model': model,
      'year': year,
      'color': color,
      'vin': vin,
      'insurancePolicyNumber': insurancePolicyNumber,
      'status': status.toInt(),
      'mileage': mileage,
      'fuelType': fuelType.toInt(),
      'seatingCapacity': seatingCapacity,
      'assignedDriverId': assignedDriverId,
      'assignedDriverName': assignedDriverName,
      'photoUrl': photoUrl,
      'internalName': internalName,
      'lastServiceDate': lastServiceDate?.toIso8601String(),
      'insuranceExpiryDate': insuranceExpiryDate.toIso8601String(),
      'registrationExpiryDate': registrationExpiryDate.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  Vehicle copyWith({
    String? id,
    String? licensePlate,
    String? make,
    String? model,
    int? year,
    String? color,
    String? vin,
    String? insurancePolicyNumber,
    VehicleStatus? status,
    int? mileage,
    FuelType? fuelType,
    int? seatingCapacity,
    String? assignedDriverId,
    String? assignedDriverName,
    String? photoUrl,
    String? internalName,
    DateTime? lastServiceDate,
    DateTime? insuranceExpiryDate,
    DateTime? registrationExpiryDate,
    DateTime? createdAt,
  }) {
    return Vehicle(
      id: id ?? this.id,
      licensePlate: licensePlate ?? this.licensePlate,
      make: make ?? this.make,
      model: model ?? this.model,
      year: year ?? this.year,
      color: color ?? this.color,
      vin: vin ?? this.vin,
      insurancePolicyNumber:
          insurancePolicyNumber ?? this.insurancePolicyNumber,
      status: status ?? this.status,
      mileage: mileage ?? this.mileage,
      fuelType: fuelType ?? this.fuelType,
      seatingCapacity: seatingCapacity ?? this.seatingCapacity,
      assignedDriverId: assignedDriverId ?? this.assignedDriverId,
      assignedDriverName: assignedDriverName ?? this.assignedDriverName,
      photoUrl: photoUrl ?? this.photoUrl,
      internalName: internalName ?? this.internalName,
      lastServiceDate: lastServiceDate ?? this.lastServiceDate,
      insuranceExpiryDate: insuranceExpiryDate ?? this.insuranceExpiryDate,
      registrationExpiryDate:
          registrationExpiryDate ?? this.registrationExpiryDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}