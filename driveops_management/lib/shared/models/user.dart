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
  final String? address;
  final DateTime? dateOfBirth;
  final DateTime? hireDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? username;
  final List<String> roles;

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
    this.address,
    this.dateOfBirth,
    this.hireDate,
    this.createdAt,
    this.updatedAt,
    this.username,
    this.roles = const [],
  });

  String get fullName => '$firstName $lastName';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: (json['id'] ?? json['keycloakId'] ?? '') as String,
      keycloakId: (json['keycloakId'] ?? json['id']) as String?,
      email: (json['email'] ?? '') as String,
      firstName: (json['firstName'] ?? json['given_name'] ?? '') as String,
      lastName: (json['lastName'] ?? json['family_name'] ?? '') as String,
      phoneNumber: json['phoneNumber'] as String?,
      userType: UserType.fromInt(json['userType'] as int? ?? 0),
      isActive: json['isActive'] as bool?,
      profileImageUrl: json['profileImageUrl'] as String?,
      address: json['address'] as String?,
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.parse(json['dateOfBirth'] as String)
          : null,
      hireDate: json['hireDate'] != null
          ? DateTime.parse(json['hireDate'] as String)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      username: json['username'] as String?,
      roles: (json['roles'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
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
      'address': address,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'hireDate': hireDate?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'username': username,
      'roles': roles,
    };
  }

  User copyWith({
    String? id,
    String? keycloakId,
    String? email,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    UserType? userType,
    bool? isActive,
    String? profileImageUrl,
    String? address,
    DateTime? dateOfBirth,
    DateTime? hireDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? username,
    List<String>? roles,
  }) {
    return User(
      id: id ?? this.id,
      keycloakId: keycloakId ?? this.keycloakId,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      userType: userType ?? this.userType,
      isActive: isActive ?? this.isActive,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      address: address ?? this.address,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      hireDate: hireDate ?? this.hireDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      username: username ?? this.username,
      roles: roles ?? this.roles,
    );
  }
}
