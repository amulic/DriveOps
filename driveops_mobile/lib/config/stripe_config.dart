/// Stripe configuration for the mobile app.
///
/// The publishable key is supplied at compile time so no key material lives in the repo:
///
/// ```sh
/// flutter run --dart-define-from-file=stripe_keys.json
/// ```
///
/// where `stripe_keys.json` (gitignored) contains:
/// `{ "STRIPE_PUBLISHABLE_KEY": "pk_test_..." }`
class StripeConfig {
  static const String publishableKey =
      String.fromEnvironment('STRIPE_PUBLISHABLE_KEY');

  static bool get isConfigured => publishableKey.isNotEmpty;
}
