enum VehicleStatus {
  available,
  inUse,
  maintenance,
  retired;

  static VehicleStatus fromInt(int value) {
    if (value >= 0 && value < values.length) {
      return values[value];
    }
    return available;
  }

  int toInt() => index;
}

enum FuelType {
  petrol,
  diesel,
  electric,
  hybrid;

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
  final VehicleStatus status;
  final int? mileage;
  final FuelType fuelType;
  final int? seatingCapacity;
  final String? assignedDriverId;
  final DateTime insuranceExpiryDate;
  final DateTime registrationExpiryDate;

  const Vehicle({
    required this.id,
    required this.licensePlate,
    required this.make,
    required this.model,
    required this.year,
    required this.color,
    required this.vin,
    required this.status,
    this.mileage,
    required this.fuelType,
    this.seatingCapacity,
    this.assignedDriverId,
    required this.insuranceExpiryDate,
    required this.registrationExpiryDate,
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
      status: VehicleStatus.fromInt(json['status'] as int),
      mileage: json['mileage'] as int?,
      fuelType: FuelType.fromInt(json['fuelType'] as int),
      seatingCapacity: json['seatingCapacity'] as int?,
      assignedDriverId: json['assignedDriverId'] as String?,
      insuranceExpiryDate:
          DateTime.parse(json['insuranceExpiryDate'] as String),
      registrationExpiryDate:
          DateTime.parse(json['registrationExpiryDate'] as String),
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
      'status': status.toInt(),
      'mileage': mileage,
      'fuelType': fuelType.toInt(),
      'seatingCapacity': seatingCapacity,
      'assignedDriverId': assignedDriverId,
      'insuranceExpiryDate': insuranceExpiryDate.toIso8601String(),
      'registrationExpiryDate': registrationExpiryDate.toIso8601String(),
    };
  }
}
