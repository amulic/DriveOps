/// Formats monetary amounts using the currency configured for real charging
/// (exposed by the API /api/config endpoint).
String currencySymbol(String? currencyCode) {
  switch ((currencyCode ?? '').toUpperCase()) {
    case 'EUR':
      return '€';
    case 'USD':
      return r'$';
    case 'GBP':
      return '£';
    default:
      return '';
  }
}

String formatMoney(num? amount, String? currencyCode) {
  if (amount == null) return '—';
  final code = (currencyCode ?? '').toUpperCase();
  final value = amount.toStringAsFixed(2);
  final symbol = currencySymbol(code);
  if (symbol.isNotEmpty) return '$symbol$value';
  return code.isEmpty ? value : '$value $code';
}

String formatMoneyWhole(num? amount, String? currencyCode) {
  if (amount == null) return '—';
  final code = (currencyCode ?? '').toUpperCase();
  final value = amount.round().toString();
  final symbol = currencySymbol(code);
  if (symbol.isNotEmpty) return '$symbol$value';
  return code.isEmpty ? value : '$value $code';
}
