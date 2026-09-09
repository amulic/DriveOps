import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driveops_management/shared/providers/repository_providers.dart';
import 'package:driveops_management/shared/dtos/requests/driver_requests.dart';
import 'package:driveops_management/services/auth_service.dart';
import 'package:driveops_management/features/drivers/presentation/providers/drivers_providers.dart';

class AddDriverDialog extends ConsumerStatefulWidget {
  const AddDriverDialog({super.key});

  @override
  ConsumerState<AddDriverDialog> createState() => _AddDriverDialogState();
}

class _AddDriverDialogState extends ConsumerState<AddDriverDialog> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _licenseNumberController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();

  DateTime? _licenseExpiryDate;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _licenseNumberController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  Future<void> _pickExpiryDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF3B82F6),
              surface: Color(0xFF252538),
            ),
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      setState(() => _licenseExpiryDate = date);
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[\w\.\-]+@[\w\.\-]+\.\w{2,}$');
    if (!emailRegex.hasMatch(value)) return 'Enter a valid email address';
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) return 'Phone number is required';
    if (value.length < 7) return 'Enter a valid phone number';
    return null;
  }

  String? _validateLicenseNumber(String? value) {
    if (value == null || value.isEmpty) return 'License number is required';
    if (value.length < 3) return 'License number must be at least 3 characters';
    return null;
  }

  Future<void> _submit() async {
    final userValid = _formKey.currentState?.validate() ?? false;
    if (_firstNameController.text.trim().isEmpty ||
        _lastNameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty) {
      return;
    }
    if (_licenseNumberController.text.trim().isEmpty || _licenseExpiryDate == null) {
      setState(() => _error = 'Please fill all required fields');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final driverRepo = ref.read(driverRepositoryProvider);

      final keycloakSub = await _authService.getKeycloakSub();
      if (keycloakSub == null) {
        setState(() => _error = 'Cannot resolve Keycloak user. Please log in again.');
        return;
      }

      final driver = await driverRepo.createDriver(CreateDriverRequest(
        keycloakId: keycloakSub,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        licenseNumber: _licenseNumberController.text.trim(),
        licenseExpiryDate: _licenseExpiryDate!,
        emergencyContactName: _emergencyNameController.text.trim().isEmpty
            ? null
            : _emergencyNameController.text.trim(),
        emergencyContactPhone: _emergencyPhoneController.text.trim().isEmpty
            ? null
            : _emergencyPhoneController.text.trim(),
      ));

      ref.invalidate(driversAsyncProvider);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Driver "${driver.firstName} ${driver.lastName}" created successfully'),
            backgroundColor: const Color(0xFF22C55E),
          ),
        );
      }
    } catch (e) {
      setState(() => _error = 'Failed to create driver: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Add New Driver',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: Colors.white54),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Create a user account and then register it as a driver.',
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'User Information',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _firstNameController,
                          label: 'First Name',
                          hint: 'e.g. John',
                          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                          textCapitalization: TextCapitalization.words,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          controller: _lastNameController,
                          label: 'Last Name',
                          hint: 'e.g. Smith',
                          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                          textCapitalization: TextCapitalization.words,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _emailController,
                    label: 'Email',
                    hint: 'e.g. john.smith@email.com',
                    validator: _validateEmail,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _phoneController,
                    label: 'Phone Number',
                    hint: 'e.g. +1-555-0100',
                    validator: _validatePhone,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Driver Information',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _licenseNumberController,
                    label: 'License Number',
                    hint: 'e.g. DL-123456',
                    validator: _validateLicenseNumber,
                    textCapitalization: TextCapitalization.characters,
                  ),
                  const SizedBox(height: 12),
                  _buildDateField(
                    label: 'License Expiry Date',
                    value: _licenseExpiryDate,
                    hint: 'Select date',
                    onTap: _pickExpiryDate,
                    validator: (v) => v == null ? 'Required — must be in the future' : null,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _emergencyNameController,
                    label: 'Emergency Contact Name (optional)',
                    hint: 'e.g. Jane Smith',
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _emergencyPhoneController,
                    label: 'Emergency Contact Phone (optional)',
                    hint: 'e.g. +1-555-9999',
                    keyboardType: TextInputType.phone,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Colors.white54),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                            : const Text('Create Driver'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required String hint,
    required VoidCallback onTap,
    String? Function(DateTime?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF252538),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value != null
                        ? '${value.month}/${value.day}/${value.year}'
                        : hint,
                    style: TextStyle(
                      color: value != null ? Colors.white : Colors.white24,
                    ),
                  ),
                ),
                const Icon(Icons.calendar_today, color: Colors.white54, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }
}