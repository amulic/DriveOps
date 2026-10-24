import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
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

/// Maps a [StripeException] to a user-friendly message, or null when it was
/// just the user cancelling the sheet (not an error worth a snackbar).
String? paymentErrorMessage(Object error) {
  if (error is StripeException) {
    final code = error.error.code;
    if (code == FailureCode.Canceled) return null;
    return error.error.localizedMessage ?? 'Payment failed. Please try again.';
  }
  return 'Payment failed. Please try again.';
}
