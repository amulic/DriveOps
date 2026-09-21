class Customer {
  final String id;
  final String keycloakId;
  final String name;
  final String phoneNumber;
  final String? email;
  final double? rating;
  final int? totalTrips;
  final int? preferredPaymentMethod;
  final DateTime? createdAt;

  const Customer({
    required this.id,
    required this.keycloakId,
    required this.name,
    required this.phoneNumber,
    this.email,
    this.rating,
    this.totalTrips,
    this.preferredPaymentMethod,
    this.createdAt,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as String,
      keycloakId: (json['keycloakId'] ?? '') as String,
      name: (json['name'] ?? '') as String,
      phoneNumber: (json['phoneNumber'] ?? '') as String,
      email: json['email'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      totalTrips: json['totalTrips'] as int?,
      preferredPaymentMethod: json['preferredPaymentMethod'] as int?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'keycloakId': keycloakId,
      'name': name,
      'phoneNumber': phoneNumber,
      'email': email,
      'rating': rating,
      'totalTrips': totalTrips,
      'preferredPaymentMethod': preferredPaymentMethod,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
