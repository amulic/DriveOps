class KeycloakCandidate {
  final String keycloakId;
  final String username;
  final String? firstName;
  final String? lastName;
  final String? email;
  final List<String> realmRoles;
  final bool hasDriverProfile;

  const KeycloakCandidate({
    required this.keycloakId,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.realmRoles,
    required this.hasDriverProfile,
  });

  String get displayName {
    final name = [firstName?.trim(), lastName?.trim()]
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .join(' ');
    return name.isEmpty ? username : name;
  }

  factory KeycloakCandidate.fromJson(Map<String, dynamic> json) {
    return KeycloakCandidate(
      keycloakId: json['keycloakId'] as String,
      username: json['username'] as String,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      email: json['email'] as String?,
      realmRoles: (json['realmRoles'] as List<dynamic>? ?? [])
          .whereType<String>()
          .toList(),
      hasDriverProfile: json['hasDriverProfile'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'keycloakId': keycloakId,
      'username': username,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'realmRoles': realmRoles,
      'hasDriverProfile': hasDriverProfile,
    };
  }
}
