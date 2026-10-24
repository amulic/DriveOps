import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driveops_management/shared/models/driver.dart';
import 'package:driveops_management/shared/models/keycloak_candidate.dart';
import 'package:driveops_management/shared/providers/repository_providers.dart';
import 'package:driveops_management/shared/dtos/requests/driver_requests.dart';
import 'package:driveops_management/services/exceptions.dart';
import 'package:driveops_management/features/drivers/presentation/providers/drivers_providers.dart';

enum _AddDriverMode { existingUser, newAccount }

class AddDriverDialog extends ConsumerStatefulWidget {
  const AddDriverDialog({super.key});

  @override
  ConsumerState<AddDriverDialog> createState() => _AddDriverDialogState();
}

class _AddDriverDialogState extends ConsumerState<AddDriverDialog> {
  final _formKey = GlobalKey<FormState>();
  final _accountFormKey = GlobalKey<FormState>();

  _AddDriverMode _mode = _AddDriverMode.existingUser;
  int _step = 1;

  final _searchController = TextEditingController();
  Timer? _searchDebounce;

  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _licenseNumberController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();

  List<KeycloakCandidate> _candidates = [];
  bool _loadingCandidates = false;
  String? _candidatesError;

  KeycloakCandidate? _selectedCandidate;
  DateTime? _licenseExpiryDate;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadCandidates();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _licenseNumberController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), _loadCandidates);
  }

  Future<void> _loadCandidates() async {
    if (!mounted) return;
    setState(() {
      _loadingCandidates = true;
      _candidatesError = null;
    });
    try {
      final candidates = await ref
          .read(driverRepositoryProvider)
          .getPromotionCandidates(_searchController.text.trim());
      if (mounted) setState(() => _candidates = candidates);
    } catch (e) {
      if (mounted) {
        setState(() {
          _candidates = [];
          _candidatesError = 'Failed to load Keycloak users: $e';
        });
      }
    } finally {
      if (mounted) setState(() => _loadingCandidates = false);
    }
  }

  void _selectCandidate(KeycloakCandidate candidate) {
    _firstNameController.text = candidate.firstName ?? '';
    _lastNameController.text = candidate.lastName ?? '';
    _emailController.text = candidate.email ?? '';
    setState(() {
      _selectedCandidate = candidate;
      _step = 2;
      _error = null;
    });
  }

  void _continueNewAccount() {
    if (!(_accountFormKey.currentState?.validate() ?? false)) return;
    setState(() {
      _step = 2;
      _error = null;
    });
  }

  void _backToStepOne() {
    setState(() {
      _step = 1;
      _selectedCandidate = null;
      _error = null;
    });
  }

  void _switchMode(_AddDriverMode mode) {
    if (_mode == mode) return;
    setState(() {
      _mode = mode;
      _error = null;
      _candidatesError = null;
    });
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

  String _localizeError(Object e) {
    if (e is ApiException) {
      if (e.statusCode == 409) {
        return _mode == _AddDriverMode.existingUser
            ? 'This Keycloak user is already linked to a driver profile.'
            : 'A Keycloak user with this username or email already exists.';
      }
      if (e.statusCode == 404) {
        return 'Keycloak user not found. Go back and select a user again.';
      }
      if (e.statusCode == 502) {
        return 'Identity service unavailable. Is Keycloak running? Try again later.';
      }
      return e.message;
    }
    return 'Failed to save driver: $e';
  }

  Future<void> _submit() async {
    if (_mode == _AddDriverMode.existingUser && _selectedCandidate == null) {
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    if (_licenseExpiryDate == null) {
      setState(() => _error = 'Please fill all required fields');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final driverRepo = ref.read(driverRepositoryProvider);
      final emergencyName = _emergencyNameController.text.trim();
      final emergencyPhone = _emergencyPhoneController.text.trim();

      final Driver driver;
      if (_mode == _AddDriverMode.existingUser) {
        driver = await driverRepo.promoteDriver(CreateDriverRequest(
          keycloakId: _selectedCandidate!.keycloakId,
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          email: _emailController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          licenseNumber: _licenseNumberController.text.trim(),
          licenseExpiryDate: _licenseExpiryDate!,
          emergencyContactName: emergencyName.isEmpty ? null : emergencyName,
          emergencyContactPhone: emergencyPhone.isEmpty ? null : emergencyPhone,
        ));
      } else {
        driver = await driverRepo.onboardDriver(OnboardDriverRequest(
          username: _usernameController.text.trim(),
          temporaryPassword: _passwordController.text,
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          email: _emailController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          licenseNumber: _licenseNumberController.text.trim(),
          licenseExpiryDate: _licenseExpiryDate!,
          emergencyContactName: emergencyName.isEmpty ? null : emergencyName,
          emergencyContactPhone: emergencyPhone.isEmpty ? null : emergencyPhone,
        ));
      }

      ref.invalidate(driversAsyncProvider);

      if (mounted) {
        Navigator.of(context).pop();
        final verb = _mode == _AddDriverMode.existingUser
            ? 'promoted'
            : 'created';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Driver "${driver.firstName} ${driver.lastName}" $verb successfully'),
            backgroundColor: const Color(0xFF22C55E),
          ),
        );
      }
    } catch (e) {
      setState(() => _error = _localizeError(e));
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
          child: _step == 1
              ? _buildStepOne(context)
              : Form(
                  key: _formKey,
                  child: _buildStepTwo(context),
                ),
        ),
      ),
    );
  }

  Widget _buildHeader(String stepLabel, String subtitle) {
    return Column(
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
        Text(
          subtitle,
          style: const TextStyle(color: Colors.white54, fontSize: 13),
        ),
        const SizedBox(height: 10),
        Text(
          stepLabel,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF3B82F6),
          ),
        ),
      ],
    );
  }

  Widget _buildStepOne(BuildContext context) {
    final isExisting = _mode == _AddDriverMode.existingUser;
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(
            'Step 1 of 2 — ${isExisting ? 'Select a Keycloak user' : 'Create a Keycloak account'}',
            isExisting
                ? 'Search for an existing Keycloak user to promote to a driver.'
                : 'Create a brand-new Keycloak account for the driver. They will be asked to change the temporary password at first login.',
          ),
          const SizedBox(height: 16),
          _buildModeSelector(),
          const SizedBox(height: 16),
          if (isExisting) ...[
            _buildSearchField(),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: _buildCandidatesList(),
            ),
          ] else
            Form(
              key: _accountFormKey,
              child: _buildNewAccountForm(),
            ),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF252538),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _buildModeTab('Existing user', _AddDriverMode.existingUser),
          _buildModeTab('New account', _AddDriverMode.newAccount),
        ],
      ),
    );
  }

  Widget _buildModeTab(String label, _AddDriverMode mode) {
    final selected = _mode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => _switchMode(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF3B82F6) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : Colors.white54,
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNewAccountForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          controller: _usernameController,
          label: 'Username',
          hint: 'e.g. jdoe',
          validator: (v) {
            final value = v?.trim() ?? '';
            if (value.length < 3) return 'Username must be at least 3 characters';
            return null;
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _firstNameController,
                label: 'First Name',
                hint: 'e.g. John',
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
                textCapitalization: TextCapitalization.words,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                controller: _lastNameController,
                label: 'Last Name',
                hint: 'e.g. Smith',
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
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
        _buildPasswordField(
          controller: _passwordController,
          label: 'Temporary Password',
          hint: 'Min. 8 characters',
          validator: (v) {
            if (v == null || v.length < 8) {
              return 'Password must be at least 8 characters';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        _buildPasswordField(
          controller: _confirmPasswordController,
          label: 'Confirm Temporary Password',
          hint: 'Repeat the password',
          validator: (v) {
            if (v != _passwordController.text) return 'Passwords do not match';
            return null;
          },
        ),
        const SizedBox(height: 20),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            onPressed: _continueNewAccount,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Continue'),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? Function(String?)? validator,
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
          obscureText: _obscurePassword,
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
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.white38,
                size: 18,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepTwo(BuildContext context) {
    final isExisting = _mode == _AddDriverMode.existingUser;
    final accountLabel = isExisting
        ? _selectedCandidate!.username
        : _usernameController.text.trim();
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(
              'Step 2 of 2 — Driver details',
              isExisting
                  ? 'Promoting "$accountLabel" — details below are prefilled and editable.'
                  : 'Creating account "$accountLabel" — complete the driver profile.'),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _firstNameController,
                  label: 'First Name',
                  hint: 'e.g. John',
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                  textCapitalization: TextCapitalization.words,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _lastNameController,
                  label: 'Last Name',
                  hint: 'e.g. Smith',
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
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
                border:
                    Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
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
                onPressed: _isLoading ? null : _backToStepOne,
                child: const Text(
                  'Back',
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
                      : Text(_mode == _AddDriverMode.existingUser
                          ? 'Promote to Driver'
                          : 'Create Driver'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Search by name, username, or email…',
        hintStyle: const TextStyle(color: Colors.white24),
        prefixIcon: const Icon(Icons.search, color: Colors.white54, size: 20),
        suffixIcon: _loadingCandidates
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF3B82F6),
                  ),
                ),
              )
            : (_searchController.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white54, size: 18),
                    onPressed: () => _searchController.clear(),
                  )),
        filled: true,
        fillColor: const Color(0xFF252538),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  Widget _buildCandidatesList() {
    if (_loadingCandidates && _candidates.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
        ),
      );
    }

    if (_candidatesError != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              _candidatesError!,
              style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13),
            ),
          ),
          OutlinedButton(
            onPressed: _loadCandidates,
            child: const Text('Retry'),
          ),
        ],
      );
    }

    if (_candidates.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'No Keycloak users found. Try a different search.',
          style: TextStyle(color: Colors.white54, fontSize: 13),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: _candidates.length,
      itemBuilder: (context, index) {
        final candidate = _candidates[index];
        return _buildCandidateTile(candidate);
      },
    );
  }

  Widget _buildCandidateTile(KeycloakCandidate candidate) {
    final isLinked = candidate.hasDriverProfile;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: isLinked ? null : () => _selectCandidate(candidate),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF252538),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isLinked
                  ? const Color(0xFF3A3A4E)
                  : const Color(0xFF3B82F6).withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            candidate.displayName,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color:
                                  isLinked ? Colors.white38 : Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            '@${candidate.username}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    if (candidate.email != null &&
                        candidate.email!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        candidate.email!,
                        overflow: TextOverflow.ellipsis,
                        style:
                            const TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                    ],
                    const SizedBox(height: 6),
                    _buildRoleChips(candidate.realmRoles),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isLinked)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3A3A4E),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Already linked',
                    style: TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                )
              else
                const Icon(Icons.chevron_right, color: Colors.white38),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleChips(List<String> roles) {
    final notable =
        roles.where((r) => !r.startsWith('default-roles-')).toList()..sort();
    if (notable.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: notable
          .map((role) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  role,
                  style: const TextStyle(
                      color: Color(0xFF3B82F6), fontSize: 10),
                ),
              ))
          .toList(),
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
