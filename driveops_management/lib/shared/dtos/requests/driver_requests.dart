class CreateDriverRequest {
  final String userId;
  final String licenseNumber;
  final DateTime licenseExpiryDate;
  final String? emergencyContactName;
  final String? emergencyContactPhone;

  const CreateDriverRequest({
    required this.userId,
    required this.licenseNumber,
    required this.licenseExpiryDate,
    this.emergencyContactName,
    this.emergencyContactPhone,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'licenseNumber': licenseNumber,
      'licenseExpiryDate': licenseExpiryDate.toIso8601String().split('T')[0],
      if (emergencyContactName != null) 'emergencyContactName': emergencyContactName,
      if (emergencyContactPhone != null) 'emergencyContactPhone': emergencyContactPhone,
    };
  }
}

class UpdateDriverRequest {
  final String? licenseNumber;
  final DateTime? licenseExpiryDate;
  final String? emergencyContactName;
  final String? emergencyContactPhone;

  const UpdateDriverRequest({
    this.licenseNumber,
    this.licenseExpiryDate,
    this.emergencyContactName,
    this.emergencyContactPhone,
  });

  Map<String, dynamic> toJson() {
    return {
      if (licenseNumber != null) 'licenseNumber': licenseNumber,
      if (licenseExpiryDate != null)
        'licenseExpiryDate': licenseExpiryDate!.toIso8601String().split('T')[0],
      if (emergencyContactName != null) 'emergencyContactName': emergencyContactName,
      if (emergencyContactPhone != null) 'emergencyContactPhone': emergencyContactPhone,
    };
  }
}

class UpdateDriverLocationRequest {
  final double latitude;
  final double longitude;

  const UpdateDriverLocationRequest({
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

class SetDriverStatusRequest {
  final bool isOnline;

  const SetDriverStatusRequest({required this.isOnline});

  Map<String, dynamic> toJson() => {'isOnline': isOnline};
}