import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:driveops_mobile/features/customer/profile/customer_profile_screen.dart';
import 'package:driveops_mobile/features/customer/providers/customer_providers.dart';
import 'package:driveops_mobile/features/customer/widgets/customer_gate.dart';
import 'package:driveops_mobile/shared/models/trip.dart';
import 'package:driveops_mobile/shared/providers/auth_provider.dart';
import 'package:driveops_mobile/shared/widgets/trip_status_chip.dart';

/// Customer welcome screen — "Welcome, {firstName}" with the two entry points
/// (request / history). The profile-onboarding gate lives in [CustomerGate].
class CustomerHomeScreen extends ConsumerWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const CustomerGate(child: _CustomerWelcome());
  }
}

class _CustomerWelcome extends ConsumerWidget {
  const _CustomerWelcome();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    // Also keeps the 30 s active-trip poll alive while the welcome screen shows.
    final activeTripAsync = ref.watch(customerActiveTripProvider);
    final activeTrip = activeTripAsync.value;

    final firstName = user?.firstName.trim() ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text('Welcome${firstName.isNotEmpty ? ', $firstName' : ''}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Your profile',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const CustomerProfileScreen(),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (activeTrip != null) ...[
                _ActiveTripCard(
                  trip: activeTrip,
                  onTap: () => context.push('/customer/trip'),
                ),
                const SizedBox(height: 32),
              ],
              SizedBox(
                width: 280,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: activeTrip != null
                      ? null
                      : () => context.push('/customer/request'),
                  icon: const Icon(Icons.local_taxi_outlined),
                  label: const Text(
                    'Request a trip',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        const Color(0xFF3B82F6).withValues(alpha: 0.3),
                    disabledForegroundColor: Colors.white38,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              if (activeTrip != null) ...[
                const SizedBox(height: 10),
                const Text(
                  'You already have an active trip.\nCancel it before requesting a new one.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: 280,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/customer/history'),
                  icon: const Icon(Icons.history),
                  label: const Text(
                    'Trip history',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveTripCard extends StatelessWidget {
  final Trip trip;
  final VoidCallback onTap;

  const _ActiveTripCard({required this.trip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1A1A2E),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Current trip',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TripStatusChip(status: trip.tripStatus),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                trip.dropoffAddress,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
              const SizedBox(height: 12),
              const Row(
                children: [
                  Icon(Icons.chevron_right, color: Color(0xFF3B82F6)),
                  SizedBox(width: 4),
                  Text(
                    'View current trip',
                    style: TextStyle(
                      color: Color(0xFF3B82F6),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
