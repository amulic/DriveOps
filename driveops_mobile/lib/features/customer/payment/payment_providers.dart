import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:driveops_mobile/config/stripe_config.dart';
import 'package:driveops_mobile/features/customer/providers/customer_providers.dart';
import 'package:driveops_mobile/services/cache_service.dart';
import 'package:driveops_mobile/services/payment_api_service.dart';
import 'package:driveops_mobile/shared/models/saved_card.dart';
import 'package:driveops_mobile/shared/providers/repository_providers.dart';

/// The customer's cards saved at Stripe (`GET /api/payment/methods`).
final savedCardsProvider = FutureProvider.autoDispose<List<SavedCard>>((ref) async {
  final api = ref.watch(paymentApiServiceProvider);
  return api.getSavedCards();
});

/// Card + trip-payment actions backed by the Stripe PaymentSheet.
/// Card numbers are entered only inside Stripe's sheet — the app never sees them.
class PaymentActions {
  final Ref _ref;

  PaymentActions(this._ref);

  /// Opens the PaymentSheet in setup mode to save a new card.
  /// Returns true when a card was saved; false when the user cancelled.
  Future<bool> addCard() async {
    // Fail fast with an actionable error instead of the cryptic plugin failure
    // when the app was launched without --dart-define-from-file=stripe_keys.json.
    if (!StripeConfig.isConfigured) {
      throw const StripeConfigException(
          'Stripe publishable key missing. Run with '
          '--dart-define-from-file=stripe_keys.json (or scripts/start-sandbox.ps1).');
    }

    final api = _ref.read(paymentApiServiceProvider);
    final session = await api.createSetupSession();

    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        setupIntentClientSecret: session.setupIntentClientSecret,
        customerEphemeralKeySecret: session.ephemeralKey,
        customerId: session.gatewayCustomerId,
        merchantDisplayName: 'DriveOps',
        style: ThemeMode.system,
      ),
    );
    await Stripe.instance.presentPaymentSheet();

    _ref.invalidate(savedCardsProvider);
    return true;
  }

  Future<void> deleteCard(String paymentMethodId) async {
    final api = _ref.read(paymentApiServiceProvider);
    await api.deleteCard(paymentMethodId);
    _ref.invalidate(savedCardsProvider);
  }

  /// Retries a failed/pending card payment for a completed trip — PaymentSheet
  /// in payment mode (handles 3DS). Returns true when Stripe confirmed the
  /// payment; false when the user cancelled. The webhook flips the trip's
  /// paymentStatus server-side, so trip providers are refreshed afterwards.
  Future<bool> retryTripPayment(String tripId) async {
    final api = _ref.read(paymentApiServiceProvider);
    final session = await api.retryTripPayment(tripId);

    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: session.paymentIntentClientSecret,
        customerEphemeralKeySecret: session.ephemeralKey,
        customerId: session.gatewayCustomerId,
        merchantDisplayName: 'DriveOps',
        style: ThemeMode.system,
      ),
    );
    await Stripe.instance.presentPaymentSheet();

    await _refreshTrips();
    // The webhook usually lands within a second — refresh once more so the
    // paid status shows without a manual pull-to-refresh.
    Future.delayed(const Duration(seconds: 2), () => _refreshTrips());
    return true;
  }

  /// Busts the Hive trips cache first — invalidating alone would re-read the
  /// cached trip rows (mirrors the history screen's pull-to-refresh).
  Future<void> _refreshTrips() async {
    final customer = await _ref.read(currentCustomerProvider.future);
    if (customer != null) {
      await _ref
          .read(cacheServiceProvider)
          .remove(CacheService.tripsCustomer(customer.id));
    }
    _ref.invalidate(customerActiveTripProvider);
    _ref.invalidate(customerTripsProvider);
  }
}

final paymentActionsProvider =
    Provider<PaymentActions>((ref) => PaymentActions(ref));

/// Maps a payment failure to a user-friendly message, or null when it was
/// just the user cancelling the sheet (not an error worth a snackbar).
/// API errors surface the server's `{message}` body and HTTP status instead
/// of the old one-size-fits-all "Payment failed".
String? paymentErrorMessage(Object error, [StackTrace? stackTrace]) {
  debugPrint('[Payment] error: $error');
  if (stackTrace != null) debugPrint('[Payment] stack: $stackTrace');
  if (error is StripeConfigException) {
    // Thrown when Stripe.publishableKey was never set — the app was launched
    // without --dart-define-from-file=stripe_keys.json (see main.dart).
    return "Payments aren't configured in this build (missing Stripe "
        'publishable key). Run the app with '
        '--dart-define-from-file=stripe_keys.json or via '
        'scripts/start-sandbox.ps1.';
  }
  if (error is MissingPluginException) {
    // The stripe plugin isn't registered in the running build — happens after
    // a hot restart/reload; only a full `flutter run` registers native plugins.
    return "Stripe isn't available in this build. Do a full flutter run — "
        "a hot restart doesn't register native plugins.";
  }
  if (error is StripeException) {
    final code = error.error.code;
    if (code == FailureCode.Canceled) return null;
    final detail = error.error.localizedMessage ?? error.error.message;
    if (detail != null && detail.isNotEmpty) return detail;
    return 'Payment failed (${error.error.stripeErrorCode ?? code.name}). '
        'Please try again.';
  }
  if (error is DioException) {
    final response = error.response;
    if (response == null) {
      return 'Could not reach the server. Check your connection and try again.';
    }
    final data = response.data;
    final serverMessage =
        data is Map<String, dynamic> ? data['message'] as String? : null;
    if (serverMessage != null && serverMessage.isNotEmpty) {
      return serverMessage;
    }
    return 'Payment failed (HTTP ${response.statusCode}). Please try again.';
  }
  return 'Payment failed. Please try again. (${error.runtimeType})';
}
