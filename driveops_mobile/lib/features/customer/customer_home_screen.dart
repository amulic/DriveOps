import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driveops_mobile/shared/dtos/requests/customer_requests.dart';
import 'package:driveops_mobile/shared/providers/auth_provider.dart';
import 'package:driveops_mobile/shared/providers/repository_providers.dart';

/// Customer home. Gates on the local Customer profile: users who self-registered
/// via Keycloak have no local row yet, so they complete their profile once
/// (phone number is required and Keycloak signup doesn't collect it).
class CustomerHomeScreen extends ConsumerWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerAsync = ref.watch(currentCustomerProvider);

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
      body: customerAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
        ),
        error: (e, _) => _ErrorState(
          message: 'Failed to load your profile: $e',
          onRetry: () => ref.invalidate(currentCustomerProvider),
        ),
        data: (customer) => customer == null
            ? const _CustomerOnboardingForm()
            : const _CustomerWelcome(),
      ),
    );
  }
}

class _CustomerWelcome extends ConsumerWidget {
  const _CustomerWelcome();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.person_pin_circle_outlined,
                color: Color(0xFF3B82F6),
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Welcome${user != null ? ', ${user.firstName}' : ''}!',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'The customer app is coming soon.\nYou will be able to request and track rides here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 40),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _CustomerOnboardingForm extends ConsumerStatefulWidget {
  const _CustomerOnboardingForm();

  @override
  ConsumerState<_CustomerOnboardingForm> createState() =>
      _CustomerOnboardingFormState();
}

class _CustomerOnboardingFormState
    extends ConsumerState<_CustomerOnboardingForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    if (user != null) {
      final fullName = '${user.firstName} ${user.lastName}'.trim();
      _nameController.text =
          fullName.isNotEmpty ? fullName : (user.username ?? '');
      _emailController.text = user.email;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(currentUserProvider);
    final sub = user?.keycloakId;
    if (sub == null) {
      setState(() => _error = 'Session expired. Please sign in again.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final email = _emailController.text.trim();
      await ref.read(customerRepositoryProvider).createCustomer(
            CreateCustomerRequest(
              keycloakId: sub,
              name: _nameController.text.trim(),
              phoneNumber: _phoneController.text.trim(),
              email: email.isEmpty ? null : email,
            ),
          );
      ref.invalidate(currentCustomerProvider);
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Could not save your profile. Please try again. ($e)');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Complete your profile',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Just one more step — we need a few details to set up your customer account.',
                  style: TextStyle(fontSize: 13, color: Colors.white54),
                ),
                const SizedBox(height: 24),
                _buildField(
                  controller: _nameController,
                  label: 'Full Name',
                  hint: 'e.g. John Smith',
                  textCapitalization: TextCapitalization.words,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Name is required' : null,
                ),
                const SizedBox(height: 16),
                _buildField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  hint: 'e.g. +1-555-0100',
                  keyboardType: TextInputType.phone,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Phone number is required';
                    }
                    if (v.trim().length < 7) return 'Enter a valid phone number';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildField(
                  controller: _emailController,
                  label: 'Email (optional)',
                  hint: 'e.g. john@email.com',
                  keyboardType: TextInputType.emailAddress,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Continue',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
              color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white24),
            filled: true,
            fillColor: const Color(0xFF252538),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
}
