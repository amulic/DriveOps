import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driveops_mobile/features/chat/presentation/providers/chat_signalr_provider.dart';
import 'package:driveops_mobile/features/customer/providers/customer_providers.dart';
import 'package:driveops_mobile/features/customer/widgets/customer_onboarding_form.dart';
import 'package:driveops_mobile/shared/providers/auth_provider.dart';
import 'package:driveops_mobile/shared/providers/location_signalr_provider.dart';
import 'package:driveops_mobile/shared/providers/notification_signalr_provider.dart';
import 'package:driveops_mobile/shared/providers/notifications_provider.dart';
import 'package:driveops_mobile/shared/providers/repository_providers.dart';

/// Wraps every customer screen: resolves the local Customer profile
/// (loading → error/retry → one-time onboarding form → child) and keeps the
/// notification + chat + location hubs and the trip-push invalidations alive
/// while the customer area is visible (same keep-alive trick as DriverShell).
class CustomerGate extends ConsumerWidget {
  final Widget child;

  const CustomerGate({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerAsync = ref.watch(currentCustomerProvider);

    return customerAsync.when(
      loading: () => const Scaffold(
        backgroundColor: Color(0xFF0F0F1A),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
        ),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: const Color(0xFF0F0F1A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1A1A2E),
          title: const Text('DriveOps'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Sign out',
              onPressed: () => ref.read(authProvider.notifier).logout(),
            ),
          ],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline,
                    color: Color(0xFFEF4444), size: 40),
                const SizedBox(height: 16),
                Text(
                  'Failed to load your profile: $e',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white54, fontSize: 14),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => ref.invalidate(currentCustomerProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (customer) {
        if (customer == null) {
          return Scaffold(
            backgroundColor: const Color(0xFF0F0F1A),
            appBar: AppBar(
              backgroundColor: const Color(0xFF1A1A2E),
              title: const Text('DriveOps'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout),
                  tooltip: 'Sign out',
                  onPressed: () => ref.read(authProvider.notifier).logout(),
                ),
              ],
            ),
            body: const CustomerOnboardingForm(),
          );
        }

        // Keep-alive: notification hub, chat hub, location hub (live driver
        // tracking on the trip screen), trip push invalidations.
        ref.watch(notificationSignalrConnectionProvider);
        ref.watch(chatSignalrConnectionProvider);
        ref.watch(locationSignalrConnectionProvider);
        ref.watch(customerTripPushProvider);
        ref.watch(notificationPushListenerProvider);

        return child;
      },
    );
  }
}
