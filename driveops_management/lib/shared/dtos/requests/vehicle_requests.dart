class CreateVehicleRequest {
  final String licensePlate;
  final String make;
  final String model;
  final int year;
  final String color;
  final String vin;
  final String insurancePolicyNumber;
  final DateTime insuranceExpiryDate;
  final DateTime registrationExpiryDate;
  final int fuelType;
  final int? seatingCapacity;

  const CreateVehicleRequest({
    required this.licensePlate,
    required this.make,
    required this.model,
    required this.year,
    required this.color,
    required this.vin,
    required this.insurancePolicyNumber,
    required this.insuranceExpiryDate,
    required this.registrationExpiryDate,
    required this.fuelType,
    this.seatingCapacity,
  });

  Map<String, dynamic> toJson() {
    return {
      'licensePlate': licensePlate,
      'make': make,
      'model': model,
      'year': year,
      'color': color,
      'vin': vin,
      'insurancePolicyNumber': insurancePolicyNumber,
      'insuranceExpiryDate': insuranceExpiryDate.toIso8601String().split('T')[0],
      'registrationExpiryDate': registrationExpiryDate.toIso8601String().split('T')[0],
      'fuelType': fuelType,
      if (seatingCapacity != null) 'seatingCapacity': seatingCapacity,
    };
  }
}

class UpdateVehicleRequest {
  final String? licensePlate;
  final String? make;
  final String? model;
  final int? year;
  final String? vin;
  final String? color;
  final String? insurancePolicyNumber;
  final DateTime? insuranceExpiryDate;
  final DateTime? registrationExpiryDate;
  final int? fuelType;
  final int? seatingCapacity;

  const UpdateVehicleRequest({
    this.licensePlate,
    this.make,
    this.model,
    this.year,
    this.vin,
    this.color,
    this.insurancePolicyNumber,
    this.insuranceExpiryDate,
    this.registrationExpiryDate,
    this.fuelType,
    this.seatingCapacity,
  });

  Map<String, dynamic> toJson() {
    return {
      if (licensePlate != null) 'licensePlate': licensePlate,
      if (make != null) 'make': make,
      if (model != null) 'model': model,
      if (year != null) 'year': year,
      if (vin != null) 'vin': vin,
      if (color != null) 'color': color,
      if (insurancePolicyNumber != null) 'insurancePolicyNumber': insurancePolicyNumber,
      if (insuranceExpiryDate != null)
        'insuranceExpiryDate': insuranceExpiryDate!.toIso8601String().split('T')[0],
      if (registrationExpiryDate != null)
        'registrationExpiryDate': registrationExpiryDate!.toIso8601String().split('T')[0],
      if (fuelType != null) 'fuelType': fuelType,
      if (seatingCapacity != null) 'seatingCapacity': seatingCapacity,
    };
  }
}

class AssignVehicleRequest {
  final String driverId;

  const AssignVehicleRequest({required this.driverId});

  Map<String, dynamic> toJson() => {'driverId': driverId};
}