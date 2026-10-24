enum DefectSeverity {
  low,
  medium,
  high,
  critical;

  static DefectSeverity fromInt(int value) {
    if (value >= 1 && value <= values.length) {
      return values[value - 1];
    }
    return medium;
  }

  int toInt() => index + 1;
}

/// Workflow states mirror the API's string column (DriveOps.Model DefectStatus).
class DefectStatus {
  static const String reported = 'Reported';
  static const String resolved = 'Resolved';
}

class DefectReport {
  final String id;
  final String vehicleId;
  final String? vehicleLicensePlate;
  final String? vehicleInternalName;
  final String driverId;
  final String? driverName;
  final String title;
  final String description;
  final DefectSeverity severity;
  final String status;
  final DateTime reportedAt;
  final DateTime? resolvedAt;
  final String? resolutionNotes;

  const DefectReport({
    required this.id,
    required this.vehicleId,
    this.vehicleLicensePlate,
    this.vehicleInternalName,
    required this.driverId,
    this.driverName,
    required this.title,
    required this.description,
    required this.severity,
    required this.status,
    required this.reportedAt,
    this.resolvedAt,
    this.resolutionNotes,
  });

  bool get isOpen => status != DefectStatus.resolved;

  factory DefectReport.fromJson(Map<String, dynamic> json) {
    return DefectReport(
      id: json['id'] as String,
      vehicleId: json['vehicleId'] as String,
      vehicleLicensePlate: json['vehicleLicensePlate'] as String?,
      vehicleInternalName: json['vehicleInternalName'] as String?,
      driverId: json['driverId'] as String,
      driverName: json['driverName'] as String?,
      title: json['title'] as String,
      description: json['description'] as String,
      severity: DefectSeverity.fromInt(json['severity'] as int),
      status: json['status'] as String,
      reportedAt: DateTime.parse(json['reportedAt'] as String),
      resolvedAt: json['resolvedAt'] != null
          ? DateTime.parse(json['resolvedAt'] as String)
          : null,
      resolutionNotes: json['resolutionNotes'] as String?,
    );
  }
}
