class CreateUserRequest {
  final String email;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final int userType;
  final String? profileImageUrl;
  final String? address;
  final DateTime? dateOfBirth;

  const CreateUserRequest({
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.userType,
    this.profileImageUrl,
    this.address,
    this.dateOfBirth,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'userType': userType,
      if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
      if (address != null) 'address': address,
      if (dateOfBirth != null) 'dateOfBirth': dateOfBirth!.toIso8601String().split('T')[0],
    };
  }
}

class UpdateUserRequest {
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final String? profileImageUrl;
  final String? address;
  final DateTime? dateOfBirth;

  const UpdateUserRequest({
    this.email,
    this.firstName,
    this.lastName,
    this.phoneNumber,
    this.profileImageUrl,
    this.address,
    this.dateOfBirth,
  });

  Map<String, dynamic> toJson() {
    return {
      if (email != null) 'email': email,
      if (firstName != null) 'firstName': firstName,
      if (lastName != null) 'lastName': lastName,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
      if (address != null) 'address': address,
      if (dateOfBirth != null) 'dateOfBirth': dateOfBirth!.toIso8601String().split('T')[0],
    };
  }
}