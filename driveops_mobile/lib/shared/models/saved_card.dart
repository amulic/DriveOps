/// A card saved at Stripe via the PaymentSheet setup flow
/// (`GET /api/payment/methods`).
class SavedCard {
  final String id;
  final String brand;
  final String last4;
  final int expMonth;
  final int expYear;

  const SavedCard({
    required this.id,
    required this.brand,
    required this.last4,
    required this.expMonth,
    required this.expYear,
  });

  factory SavedCard.fromJson(Map<String, dynamic> json) => SavedCard(
        id: json['id'] as String,
        brand: json['brand'] as String? ?? 'card',
        last4: json['last4'] as String? ?? '****',
        expMonth: json['expMonth'] as int? ?? 0,
        expYear: json['expYear'] as int? ?? 0,
      );
}
