enum UserType {
  customer,
  driver,
  admin,
  dispatcher;

  static UserType fromInt(int value) {
    if (value >= 0 && value < values.length) {
      return values[value];
    }
    return customer;
  }

  int toInt() => index;
}

class User {
  final String id;
  final String? keycloakId;
  final String email;
  final String firstName;
  final String lastName;
  final String? phoneNumber;
  final UserType userType;
  final bool? isActive;
  final String? profileImageUrl;

  const User({
    required this.id,
    this.keycloakId,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
    required this.userType,
    this.isActive,
    this.profileImageUrl,
  });

  String get fullName => '$firstName $lastName';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      keycloakId: json['keycloakId'] as String?,
      email: json['email'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      phoneNumber: json['phoneNumber'] as String?,
      userType: UserType.fromInt(json['userType'] as int),
      isActive: json['isActive'] as bool?,
      profileImageUrl: json['profileImageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'keycloakId': keycloakId,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'userType': userType.toInt(),
      'isActive': isActive,
      'profileImageUrl': profileImageUrl,
    };
  }
}
