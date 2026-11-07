import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driveops_mobile/features/customer/payment/payment_providers.dart';
import 'package:driveops_mobile/shared/models/saved_card.dart';

/// Lists the customer's cards saved at Stripe and adds/removes them via the
/// Stripe PaymentSheet (setup mode). Opened from the customer profile screen.
class PaymentMethodsScreen extends ConsumerStatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  ConsumerState<PaymentMethodsScreen> createState() =>
      _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends ConsumerState<PaymentMethodsScreen> {
  bool _busy = false;

  Future<void> _addCard() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final added = await ref.read(paymentActionsProvider).addCard();
      if (added && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Card saved.')),
        );
      }
    } catch (e, st) {
      final message = paymentErrorMessage(e, st);
      if (message != null && mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteCard(SavedCard card) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Remove card?', style: TextStyle(color: Colors.white)),
        content: Text(
          '${card.brand} •••• ${card.last4} will be removed from your account.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child:
                const Text('Remove', style: TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref.read(paymentActionsProvider).deleteCard(card.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not remove the card.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardsAsync = ref.watch(savedCardsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Payment methods'),
      ),
      body: cardsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
        ),
        error: (e, st) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline,
                    color: Color(0xFFEF4444), size: 40),
                const SizedBox(height: 16),
                Text(
                  'Failed to load your cards.\n${paymentErrorMessage(e, st) ?? 'Unexpected error.'}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white54, fontSize: 14),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => ref.invalidate(savedCardsProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (cards) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (cards.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Column(
                  children: [
                    Icon(Icons.credit_card_off_outlined,
                        color: Colors.white24, size: 48),
                    SizedBox(height: 16),
                    Text(
                      'No cards saved yet.\nAdd one to pay for trips by card.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54, fontSize: 14),
                    ),
                  ],
                ),
              )
            else
              ...cards.map(_buildCardTile),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _busy ? null : _addCard,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.add_card),
                label: Text(
                  _busy ? 'Opening…' : 'Add card',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Cards are stored securely by Stripe — DriveOps never sees your card number.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardTile(SavedCard card) {
    return Card(
      color: const Color(0xFF1A1A2E),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.credit_card, color: Color(0xFF3B82F6)),
        title: Text(
          '${card.brand} •••• ${card.last4}',
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'Expires ${card.expMonth.toString().padLeft(2, '0')}/${card.expYear}',
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
          onPressed: () => _deleteCard(card),
        ),
      ),
    );
  }
}
