import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driveops_mobile/features/customer/payment/payment_providers.dart';
import 'package:driveops_mobile/shared/models/trip.dart';

/// True when a completed card trip still needs the customer to pay
/// (off-session charge failed or never resolved).
bool tripNeedsPayment(Trip trip) =>
    trip.tripStatus == TripStatus.completed &&
    (trip.paymentMethod == PaymentMethod.creditCard ||
        trip.paymentMethod == PaymentMethod.debitCard) &&
    (trip.paymentStatus == PaymentStatus.failed ||
        trip.paymentStatus == PaymentStatus.pending);

/// Banner shown on completed card trips whose charge failed (or is stuck
/// pending): explains the state and offers a "Pay now" retry via the Stripe
/// PaymentSheet. Used on the history tile and the trip details dialog.
class PaymentStatusBanner extends ConsumerStatefulWidget {
  final Trip trip;

  /// Compact mode for list tiles; the banner otherwise breathes a bit more.
  final bool compact;

  const PaymentStatusBanner({super.key, required this.trip, this.compact = false});

  @override
  ConsumerState<PaymentStatusBanner> createState() =>
      _PaymentStatusBannerState();
}

class _PaymentStatusBannerState extends ConsumerState<PaymentStatusBanner> {
  bool _paying = false;

  Future<void> _payNow() async {
    if (_paying) return;
    setState(() => _paying = true);
    try {
      final paid = await ref
          .read(paymentActionsProvider)
          .retryTripPayment(widget.trip.id);
      if (paid && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment successful. Thank you!')),
        );
      }
    } catch (e) {
      final message = paymentErrorMessage(e);
      if (message != null && mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final failed = widget.trip.paymentStatus == PaymentStatus.failed;

    return Container(
      margin: EdgeInsets.only(top: widget.compact ? 8 : 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              failed
                  ? 'Card payment failed'
                  : 'Card payment still processing',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
          if (failed)
            TextButton(
              onPressed: _paying ? null : _payNow,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF3B82F6),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 32),
              ),
              child: _paying
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF3B82F6),
                      ),
                    )
                  : const Text('Pay now',
                      style: TextStyle(fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }
}
