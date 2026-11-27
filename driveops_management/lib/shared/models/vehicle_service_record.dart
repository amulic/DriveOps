class VehicleServiceRecord {
  final String id;
  final String vehicleId;
  final DateTime serviceDate;
  final String serviceType;
  final String? description;
  final String? performedBy;
  final double? odometerKm;
  final double? cost;
  final DateTime? createdAt;

  const VehicleServiceRecord({
    required this.id,
    required this.vehicleId,
    required this.serviceDate,
    required this.serviceType,
    this.description,
    this.performedBy,
    this.odometerKm,
    this.cost,
    this.createdAt,
  });

  factory VehicleServiceRecord.fromJson(Map<String, dynamic> json) {
    return VehicleServiceRecord(
      id: json['id'] as String,
      vehicleId: json['vehicleId'] as String,
      serviceDate: DateTime.parse(json['serviceDate'] as String),
      serviceType: json['serviceType'] as String? ?? 'RoutineMaintenance',
      description: json['description'] as String?,
      performedBy: json['performedBy'] as String?,
      odometerKm: (json['odometerKm'] as num?)?.toDouble(),
      cost: (json['cost'] as num?)?.toDouble(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  String get serviceTypeLabel {
    switch (serviceType) {
      case 'Inspection':
        return 'Inspection';
      case 'Repair':
        return 'Repair';
      case 'Other':
        return 'Other';
      case 'RoutineMaintenance':
      default:
        return 'Routine maintenance';
    }
  }
}

class VehicleServiceReminder {
  final String vehicleId;
  final String licensePlate;
  final String make;
  final String model;
  /// "Service" or "Inspection".
  final String type;
  final String reason;
  final DateTime? dueAt;

  const VehicleServiceReminder({
    required this.vehicleId,
    required this.licensePlate,
    required this.make,
    required this.model,
    required this.type,
    required this.reason,
    this.dueAt,
  });

  factory VehicleServiceReminder.fromJson(Map<String, dynamic> json) {
    return VehicleServiceReminder(
      vehicleId: json['vehicleId'] as String,
      licensePlate: json['licensePlate'] as String? ?? '',
      make: json['make'] as String? ?? '',
      model: json['model'] as String? ?? '',
      type: json['type'] as String? ?? 'Service',
      reason: json['reason'] as String? ?? '',
      dueAt: json['dueAt'] != null
          ? DateTime.parse(json['dueAt'] as String)
          : null,
    );
  }
}
