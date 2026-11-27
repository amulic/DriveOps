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

class CreateVehicleServiceRecordRequest {
  final DateTime serviceDate;
  final String serviceType;
  final String? description;
  final String? performedBy;
  final double? odometerKm;
  final double? cost;

  const CreateVehicleServiceRecordRequest({
    required this.serviceDate,
    required this.serviceType,
    this.description,
    this.performedBy,
    this.odometerKm,
    this.cost,
  });

  Map<String, dynamic> toJson() {
    return {
      'serviceDate': serviceDate.toIso8601String(),
      'serviceType': _serviceTypeCode,
      if (description != null && description!.trim().isNotEmpty)
        'description': description,
      if (performedBy != null && performedBy!.trim().isNotEmpty)
        'performedBy': performedBy,
      if (odometerKm != null) 'odometerKm': odometerKm,
      if (cost != null) 'cost': cost,
    };
  }

  // The API expects the numeric enum value (System.Text.Json default).
  int get _serviceTypeCode {
    switch (serviceType) {
      case 'Inspection':
        return 2;
      case 'Repair':
        return 3;
      case 'Other':
        return 4;
      case 'RoutineMaintenance':
      default:
        return 1;
    }
  }
}