class CreateAccountPayload {
  final String username;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String temporaryPassword;
  final List<String> roles;

  const CreateAccountPayload({
    required this.username,
    required this.temporaryPassword,
    this.email,
    this.firstName,
    this.lastName,
    this.roles = const [],
  });

  Map<String, dynamic> toJson() => {
        'username': username,
        if (email != null && email!.isNotEmpty) 'email': email,
        if (firstName != null && firstName!.isNotEmpty) 'firstName': firstName,
        if (lastName != null && lastName!.isNotEmpty) 'lastName': lastName,
        'temporaryPassword': temporaryPassword,
        'roles': roles,
      };
}

class UpdateAccountPayload {
  final String? firstName;
  final String? lastName;
  final String? email;
  final bool? enabled;

  const UpdateAccountPayload({
    this.firstName,
    this.lastName,
    this.email,
    this.enabled,
  });

  Map<String, dynamic> toJson() => {
        if (firstName != null) 'firstName': firstName,
        if (lastName != null) 'lastName': lastName,
        if (email != null) 'email': email,
        if (enabled != null) 'enabled': enabled,
      };
}

class UpdateFareSettingsPayload {
  final double baseFare;
  final double perKmRate;
  final double perMinuteRate;
  final double premiumMultiplier;
  final double sharedMultiplier;

  const UpdateFareSettingsPayload({
    required this.baseFare,
    required this.perKmRate,
    required this.perMinuteRate,
    required this.premiumMultiplier,
    required this.sharedMultiplier,
  });

  Map<String, dynamic> toJson() => {
        'baseFare': baseFare,
        'perKmRate': perKmRate,
        'perMinuteRate': perMinuteRate,
        'premiumMultiplier': premiumMultiplier,
        'sharedMultiplier': sharedMultiplier,
      };
}
