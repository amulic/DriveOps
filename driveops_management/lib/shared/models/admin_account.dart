class AdminAccount {
  final String id;
  final String username;
  final String? email;
  final String? firstName;
  final String? lastName;
  final bool enabled;
  final List<String> roles;

  const AdminAccount({
    required this.id,
    required this.username,
    this.email,
    this.firstName,
    this.lastName,
    required this.enabled,
    required this.roles,
  });

  String get displayName {
    final name = '${firstName ?? ''} ${lastName ?? ''}'.trim();
    return name.isEmpty ? username : name;
  }

  factory AdminAccount.fromJson(Map<String, dynamic> json) {
    return AdminAccount(
      id: json['id'] as String,
      username: json['username'] as String? ?? '',
      email: json['email'] as String?,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      enabled: json['enabled'] as bool? ?? true,
      roles: (json['roles'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );
  }
}

class FareSettings {
  final double baseFare;
  final double perKmRate;
  final double perMinuteRate;
  final double premiumMultiplier;
  final double sharedMultiplier;
  final String currency;

  const FareSettings({
    required this.baseFare,
    required this.perKmRate,
    required this.perMinuteRate,
    required this.premiumMultiplier,
    required this.sharedMultiplier,
    required this.currency,
  });

  factory FareSettings.fromJson(Map<String, dynamic> json) {
    return FareSettings(
      baseFare: (json['baseFare'] as num?)?.toDouble() ?? 0,
      perKmRate: (json['perKmRate'] as num?)?.toDouble() ?? 0,
      perMinuteRate: (json['perMinuteRate'] as num?)?.toDouble() ?? 0,
      premiumMultiplier: (json['premiumMultiplier'] as num?)?.toDouble() ?? 1,
      sharedMultiplier: (json['sharedMultiplier'] as num?)?.toDouble() ?? 1,
      currency: json['currency'] as String? ?? 'EUR',
    );
  }
}
