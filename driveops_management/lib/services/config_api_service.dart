import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driveops_management/services/api_service.dart';

/// Currency used for real charging, read from the same server configuration that
/// drives Stripe. Falls back to EUR (the backend default) if unreachable.
final currencyProvider = FutureProvider<String>((ref) async {
  try {
    final api = ref.watch(apiServiceProvider);
    final response = await api.get('/api/config');
    final data = response.data as Map<String, dynamic>;
    final currency = data['currency'] as String?;
    return (currency == null || currency.isEmpty) ? 'EUR' : currency;
  } catch (_) {
    return 'EUR';
  }
});

/// Synchronous accessor for widgets: last known currency (or the default while loading).
final currencyCodeProvider = Provider<String>((ref) {
  return ref.watch(currencyProvider).value ?? 'EUR';
});
