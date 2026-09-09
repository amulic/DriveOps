class CreateDriverRequest {
  final String keycloakId;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String licenseNumber;
  final DateTime licenseExpiryDate;
  final String? emergencyContactName;
  final String? emergencyContactPhone;

  const CreateDriverRequest({
    required this.keycloakId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.licenseNumber,
    required this.licenseExpiryDate,
    this.emergencyContactName,
    this.emergencyContactPhone,
  });

  Map<String, dynamic> toJson() {
    return {
      'keycloakId': keycloakId,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phoneNumber': phoneNumber,
      'licenseNumber': licenseNumber,
      'licenseExpiryDate': licenseExpiryDate.toIso8601String().split('T')[0],
      if (emergencyContactName != null) 'emergencyContactName': emergencyContactName,
      if (emergencyContactPhone != null) 'emergencyContactPhone': emergencyContactPhone,
    };
  }
}

class UpdateDriverRequest {
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phoneNumber;
  final String? licenseNumber;
  final DateTime? licenseExpiryDate;
  final String? emergencyContactName;
  final String? emergencyContactPhone;

  const UpdateDriverRequest({
    this.firstName,
    this.lastName,
    this.email,
    this.phoneNumber,
    this.licenseNumber,
    this.licenseExpiryDate,
    this.emergencyContactName,
    this.emergencyContactPhone,
  });

  Map<String, dynamic> toJson() {
    return {
      if (firstName != null) 'firstName': firstName,
      if (lastName != null) 'lastName': lastName,
      if (email != null) 'email': email,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
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
