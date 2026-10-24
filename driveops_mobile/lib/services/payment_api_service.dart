import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driveops_mobile/config/api_config.dart';
import 'package:driveops_mobile/services/api_service.dart';
import 'package:driveops_mobile/shared/models/saved_card.dart';

final paymentApiServiceProvider = Provider<PaymentApiService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return PaymentApiService(apiService);
});

/// Response of `POST /api/payment/setup-intent` — everything PaymentSheet
/// needs in setup mode.
class SetupSession {
  final String setupIntentClientSecret;
  final String ephemeralKey;
  final String gatewayCustomerId;

  const SetupSession({
    required this.setupIntentClientSecret,
    required this.ephemeralKey,
    required this.gatewayCustomerId,
  });

  factory SetupSession.fromJson(Map<String, dynamic> json) => SetupSession(
        setupIntentClientSecret: json['setupIntentClientSecret'] as String,
        ephemeralKey: json['ephemeralKey'] as String,
        gatewayCustomerId: json['gatewayCustomerId'] as String,
      );
}

/// Response of `POST /api/payment/trips/{id}/retry` — everything PaymentSheet
/// needs in payment mode.
class RetryPaymentSession {
  final String paymentIntentClientSecret;
  final String ephemeralKey;
  final String gatewayCustomerId;

  const RetryPaymentSession({
    required this.paymentIntentClientSecret,
    required this.ephemeralKey,
    required this.gatewayCustomerId,
  });

  factory RetryPaymentSession.fromJson(Map<String, dynamic> json) =>
      RetryPaymentSession(
        paymentIntentClientSecret: json['paymentIntentClientSecret'] as String,
        ephemeralKey: json['ephemeralKey'] as String,
        gatewayCustomerId: json['gatewayCustomerId'] as String,
      );
}

/// Thin wrapper over the API's Stripe-backed payment endpoints.
/// Card numbers never pass through here — only Stripe client secrets.
class PaymentApiService {
  final ApiService _api;

  PaymentApiService(this._api);

  Future<SetupSession> createSetupSession() async {
    final response =
        await _api.post('${ApiConfig.paymentEndpoint}/setup-intent');
    return SetupSession.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<SavedCard>> getSavedCards() async {
    final response = await _api.get('${ApiConfig.paymentEndpoint}/methods');
    return (response.data as List<dynamic>)
        .map((c) => SavedCard.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  Future<void> deleteCard(String paymentMethodId) async {
    await _api.delete('${ApiConfig.paymentEndpoint}/methods/$paymentMethodId');
  }

  Future<RetryPaymentSession> retryTripPayment(String tripId) async {
    final response =
        await _api.post('${ApiConfig.paymentEndpoint}/trips/$tripId/retry');
    return RetryPaymentSession.fromJson(response.data as Map<String, dynamic>);
  }
}
