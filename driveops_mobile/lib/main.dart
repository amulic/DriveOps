import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:driveops_mobile/app.dart';
import 'package:driveops_mobile/config/stripe_config.dart';
import 'package:driveops_mobile/services/cache_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CacheService().init();
  // Publishable key comes from --dart-define-from-file=stripe_keys.json (gitignored).
  if (StripeConfig.isConfigured) {
    Stripe.publishableKey = StripeConfig.publishableKey;
    await Stripe.instance.applySettings();
  } else {
    // Without it the PaymentSheet throws deep inside flutter_stripe — say so now.
    debugPrint('==============================================================');
    debugPrint('STRIPE_PUBLISHABLE_KEY not set — card payments will fail.');
    debugPrint('Run with --dart-define-from-file=stripe_keys.json');
    debugPrint('(or scripts/start-sandbox.ps1, which passes it automatically).');
    debugPrint('==============================================================');
  }
  runApp(const ProviderScope(child: DriveOpsMobileApp()));
}
