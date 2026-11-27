import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driveops_mobile/shared/dtos/requests/driver_requests.dart';
import 'package:driveops_mobile/shared/models/driver.dart';
import 'package:driveops_mobile/shared/providers/repository_providers.dart';

/// Lets a driver maintain the personal details of their own profile.
/// Administrative fields (status, license verification, ratings, assignment)
/// remain staff-controlled.
class DriverProfileEditScreen extends ConsumerStatefulWidget {
  final Driver driver;

  const DriverProfileEditScreen({super.key, required this.driver});

  @override
  ConsumerState<DriverProfileEditScreen> createState() =>
      _DriverProfileEditScreenState();
}

class _DriverProfileEditScreenState
    extends ConsumerState<DriverProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _emergencyName;
  late final TextEditingController _emergencyPhone;
  late final TextEditingController _photoUrl;

  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final d = widget.driver;
    _firstName = TextEditingController(text: d.firstName);
    _lastName = TextEditingController(text: d.lastName);
    _email = TextEditingController(text: d.email);
    _phone = TextEditingController(text: d.phoneNumber);
    _emergencyName = TextEditingController(text: d.emergencyContactName ?? '');
    _emergencyPhone = TextEditingController(text: d.emergencyContactPhone ?? '');
    _photoUrl = TextEditingController(text: d.profileImageUrl ?? '');
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    _emergencyName.dispose();
    _emergencyPhone.dispose();
    _photoUrl.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return null;
    if (!RegExp(r'^[\w\.\-]+@[\w\.\-]+\.\w{2,}$').hasMatch(v)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await ref.read(driverRepositoryProvider).updateOwnProfile(
            UpdateOwnDriverProfileRequest(
              firstName: _firstName.text.trim(),
              lastName: _lastName.text.trim(),
              email: _email.text.trim(),
              phoneNumber: _phone.text.trim(),
              emergencyContactName: _emergencyName.text.trim(),
              emergencyContactPhone: _emergencyPhone.text.trim(),
              profileImageUrl: _photoUrl.text.trim(),
            ),
          );
      ref.invalidate(currentDriverProvider);
      if (mounted) Navigator.of(context).pop(true);
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = data is Map<String, dynamic>
          ? data['message'] as String?
          : null;
      if (mounted) {
        setState(() =>
            _error = message ?? 'Could not save your profile. Please try again.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Could not save your profile. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('My profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Personal details',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              const Text(
                'These details are shown to operations and customers. License '
                'and account status are managed by the operations team.',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: _field(_firstName, 'First name',
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Required'
                        : null)),
                const SizedBox(width: 12),
                Expanded(child: _field(_lastName, 'Last name',
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Required'
                        : null)),
              ]),
              const SizedBox(height: 12),
              _field(_email, 'Email (optional)',
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail),
              const SizedBox(height: 12),
              _field(_phone, 'Phone number',
                  keyboardType: TextInputType.phone,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Phone number is required'
                      : null),
              const SizedBox(height: 12),
              _field(_emergencyName, 'Emergency contact name (optional)'),
              const SizedBox(height: 12),
              _field(_emergencyPhone, 'Emergency contact phone (optional)',
                  keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
              _field(_photoUrl, 'Profile photo URL (optional)',
                  keyboardType: TextInputType.url),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!,
                    style: const TextStyle(
                        color: Color(0xFFEF4444), fontSize: 13)),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Save changes',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: const Color(0xFF252538),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
