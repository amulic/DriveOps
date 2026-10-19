class CreateCustomerRequest {
  final String keycloakId;
  final String name;
  final String phoneNumber;
  final String? email;

  const CreateCustomerRequest({
    required this.keycloakId,
    required this.name,
    required this.phoneNumber,
    this.email,
  });

  Map<String, dynamic> toJson() {
    return {
      'keycloakId': keycloakId,
      'name': name,
      'phoneNumber': phoneNumber,
      if (email != null) 'email': email,
    };
  }
}

class UpdateCustomerRequest {
  final String name;
  final String phoneNumber;
  final String? email;

  const UpdateCustomerRequest({
    required this.name,
    required this.phoneNumber,
    this.email,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phoneNumber': phoneNumber,
      'email': email,
    };
  }
}
