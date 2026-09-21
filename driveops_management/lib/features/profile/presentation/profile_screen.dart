import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:driveops_management/config/api_config.dart';
import 'package:driveops_management/services/exceptions.dart';
import 'package:driveops_management/services/keycloak_account_service.dart';
import 'package:driveops_management/shared/models/user.dart';
import 'package:driveops_management/shared/providers/auth_provider.dart';
import 'package:driveops_management/features/profile/presentation/providers/profile_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final accountProfile = ref.watch(accountProfileProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 380,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 12, 24),
                    child: Column(
                      children: [
                        _IdentityCard(
                          user: user,
                          profile: accountProfile.value,
                        ),
                        const SizedBox(height: 16),
                        _AccountDetailsCard(
                          user: user,
                          profile: accountProfile.value,
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(12, 0, 24, 24),
                    child: Column(
                      children: [
                        accountProfile.when(
                          data: (profile) => _PersonalInfoCard(
                            key: ValueKey(
                              '${profile.firstName}|${profile.lastName}|${profile.email}',
                            ),
                            profile: profile,
                          ),
                          loading: () => const _LoadingCard(),
                          error: (error, _) => _ErrorCard(
                            message: _errorMessage(error),
                            onRetry: () =>
                                ref.invalidate(accountProfileProvider),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const _SecurityCard(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Text(
        'Profile',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  static String _errorMessage(Object error) {
    if (error is ApiException) return error.message;
    return error.toString();
  }
}

// ---------------------------------------------------------------------------
// Identity card (avatar, name, role)
// ---------------------------------------------------------------------------

class _IdentityCard extends StatelessWidget {
  final User? user;
  final KeycloakAccountProfile? profile;

  const _IdentityCard({required this.user, this.profile});

  @override
  Widget build(BuildContext context) {
    final name = (profile?.fullName.isNotEmpty == true)
        ? profile!.fullName
        : (user?.fullName.trim().isNotEmpty == true
            ? user!.fullName
            : (user?.username ?? 'User'));
    final initials = name
        .split(' ')
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0])
        .join()
        .toUpperCase();
    final email = profile?.email.isNotEmpty == true
        ? profile!.email
        : (user?.email ?? '');

    return _Card(
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: const Color(0xFF3B82F6),
            child: Text(
              initials.isEmpty ? '?' : initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 28,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          _RoleChip(userType: user?.userType),
          if (email.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              email,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final UserType? userType;

  const _RoleChip({this.userType});

  @override
  Widget build(BuildContext context) {
    final label = switch (userType) {
      UserType.admin => 'Administrator',
      UserType.dispatcher => 'Dispatcher',
      UserType.driver => 'Driver',
      UserType.customer => 'Customer',
      null => 'User',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF3B82F6),
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Account details card (read-only Keycloak account info)
// ---------------------------------------------------------------------------

class _AccountDetailsCard extends StatelessWidget {
  final User? user;
  final KeycloakAccountProfile? profile;

  const _AccountDetailsCard({required this.user, this.profile});

  static const _appRoles = {'admin', 'dispatcher', 'driver', 'customer'};

  @override
  Widget build(BuildContext context) {
    final username = profile?.username.isNotEmpty == true
        ? profile!.username
        : (user?.username ?? '—');
    final keycloakId = user?.keycloakId ?? '—';
    final roles = (user?.roles ?? const [])
        .where((r) => _appRoles.contains(r))
        .toList();
    final emailVerified = profile?.emailVerified;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle(icon: Icons.badge_outlined, title: 'Account Details'),
          const SizedBox(height: 16),
          _DetailRow(label: 'Username', value: username),
          const SizedBox(height: 12),
          _DetailRow(
            label: 'Keycloak ID',
            value: keycloakId,
            monospace: true,
            onCopy: user?.keycloakId != null
                ? () {
                    Clipboard.setData(
                      ClipboardData(text: user!.keycloakId!),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Keycloak ID copied to clipboard'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                : null,
          ),
          const SizedBox(height: 12),
          _DetailRow(
            label: 'Email verified',
            value: emailVerified == null
                ? '—'
                : (emailVerified ? 'Yes' : 'No'),
          ),
          const SizedBox(height: 12),
          const Text(
            'Roles',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: roles.isEmpty
                ? [
                    const Text(
                      '—',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ]
                : roles
                    .map(
                      (role) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          role,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    )
                    .toList(),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool monospace;
  final VoidCallback? onCopy;

  const _DetailRow({
    required this.label,
    required this.value,
    this.monospace = false,
    this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontFamily: monospace ? 'monospace' : null,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (onCopy != null)
          InkWell(
            onTap: onCopy,
            borderRadius: BorderRadius.circular(4),
            child: const Padding(
              padding: EdgeInsets.all(2),
              child: Icon(Icons.copy, size: 14, color: Colors.white38),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Personal information card (editable via Keycloak Account API)
// ---------------------------------------------------------------------------

class _PersonalInfoCard extends ConsumerStatefulWidget {
  final KeycloakAccountProfile profile;

  const _PersonalInfoCard({super.key, required this.profile});

  @override
  ConsumerState<_PersonalInfoCard> createState() => _PersonalInfoCardState();
}

class _PersonalInfoCardState extends ConsumerState<_PersonalInfoCard> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;

  bool _isSaving = false;
  String? _error;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.profile.firstName);
    _lastNameController = TextEditingController(text: widget.profile.lastName);
    _emailController = TextEditingController(text: widget.profile.email);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) return '$fieldName is required';
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[\w\.\-]+@[\w\.\-]+\.\w{2,}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSaving = true;
      _error = null;
      _saved = false;
    });

    try {
      final service = ref.read(keycloakAccountServiceProvider);
      await service.updateProfile(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
      );

      // Refresh the account profile and the JWT-derived user (sidebar etc.).
      ref.invalidate(accountProfileProvider);
      await ref.read(authProvider.notifier).reloadUser();

      if (mounted) {
        setState(() => _saved = true);
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _CardTitle(
              icon: Icons.person_outline,
              title: 'Personal Information',
            ),
            const SizedBox(height: 8),
            const Text(
              'Stored in Keycloak and used across all DriveOps services.',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _ProfileTextField(
                    controller: _firstNameController,
                    label: 'First Name',
                    validator: (v) => _validateRequired(v, 'First name'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _ProfileTextField(
                    controller: _lastNameController,
                    label: 'Last Name',
                    validator: (v) => _validateRequired(v, 'Last name'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _ProfileTextField(
              controller: _emailController,
              label: 'Email',
              keyboardType: TextInputType.emailAddress,
              validator: _validateEmail,
            ),
            const SizedBox(height: 20),
            if (_error != null) ...[
              _FeedbackBanner(message: _error!, isError: true),
              const SizedBox(height: 16),
            ],
            if (_saved) ...[
              const _FeedbackBanner(
                message: 'Profile updated successfully.',
                isError: false,
              ),
              const SizedBox(height: 16),
            ],
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save, size: 18),
                label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Security card (change password + Keycloak Account Console link)
// ---------------------------------------------------------------------------

class _SecurityCard extends ConsumerStatefulWidget {
  const _SecurityCard();

  @override
  ConsumerState<_SecurityCard> createState() => _SecurityCardState();
}

class _SecurityCardState extends ConsumerState<_SecurityCard> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isSaving = false;
  String? _error;
  bool _changed = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateNewPassword(String? value) {
    if (value == null || value.isEmpty) return 'New password is required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    if (value == _currentPasswordController.text) {
      return 'New password must differ from the current one';
    }
    return null;
  }

  String? _validateConfirm(String? value) {
    if (value == null || value.isEmpty) return 'Please confirm the password';
    if (value != _newPasswordController.text) return 'Passwords do not match';
    return null;
  }

  Future<void> _changePassword() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSaving = true;
      _error = null;
      _changed = false;
    });

    try {
      final service = ref.read(keycloakAccountServiceProvider);
      await service.changePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      if (mounted) {
        setState(() {
          _changed = true;
          _currentPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _openAccountConsole() async {
    final uri = Uri.parse(KeycloakConfig.accountUrl);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not open the Keycloak Account Console.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle(icon: Icons.lock_outline, title: 'Security'),
          const SizedBox(height: 8),
          const Text(
            'Change your Keycloak password. This may sign you out of other sessions.',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
          const SizedBox(height: 20),
          Form(
            key: _formKey,
            child: Column(
              children: [
                _ProfileTextField(
                  controller: _currentPasswordController,
                  label: 'Current Password',
                  obscureText: _obscureCurrent,
                  validator: (v) => (v == null || v.isEmpty)
                      ? 'Current password is required'
                      : null,
                  suffixIcon: _visibilityToggle(
                    _obscureCurrent,
                    () => setState(() => _obscureCurrent = !_obscureCurrent),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _ProfileTextField(
                        controller: _newPasswordController,
                        label: 'New Password',
                        obscureText: _obscureNew,
                        validator: _validateNewPassword,
                        suffixIcon: _visibilityToggle(
                          _obscureNew,
                          () => setState(() => _obscureNew = !_obscureNew),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _ProfileTextField(
                        controller: _confirmPasswordController,
                        label: 'Confirm New Password',
                        obscureText: _obscureConfirm,
                        validator: _validateConfirm,
                        suffixIcon: _visibilityToggle(
                          _obscureConfirm,
                          () => setState(
                            () => _obscureConfirm = !_obscureConfirm,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (_error != null) ...[
            _FeedbackBanner(message: _error!, isError: true),
            const SizedBox(height: 16),
          ],
          if (_changed) ...[
            const _FeedbackBanner(
              message: 'Password changed successfully.',
              isError: false,
            ),
            const SizedBox(height: 16),
          ],
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _isSaving ? null : _changePassword,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.key, size: 18),
              label: Text(_isSaving ? 'Updating...' : 'Update Password'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Manage two-factor authentication, sessions and more in the '
                  'Keycloak Account Console.',
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: _openAccountConsole,
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('Open Account Console'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF3B82F6),
                  side: const BorderSide(color: Color(0xFF3B82F6)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _visibilityToggle(bool obscure, VoidCallback onTap) {
    return IconButton(
      icon: Icon(
        obscure ? Icons.visibility_off : Icons.visibility,
        size: 18,
        color: Colors.white38,
      ),
      onPressed: onTap,
    );
  }
}

// ---------------------------------------------------------------------------
// Shared building blocks
// ---------------------------------------------------------------------------

class _Card extends StatelessWidget {
  final Widget child;

  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF252538),
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}

class _CardTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _CardTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF3B82F6), size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

class _ProfileTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;

  const _ProfileTextField({
    required this.controller,
    required this.label,
    this.validator,
    this.obscureText = false,
    this.keyboardType,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
        filled: true,
        fillColor: const Color(0xFF1A1A2E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF3B82F6)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
        errorStyle: const TextStyle(color: Color(0xFFEF4444), fontSize: 12),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        suffixIcon: suffixIcon,
      ),
    );
  }
}

class _FeedbackBanner extends StatelessWidget {
  final String message;
  final bool isError;

  const _FeedbackBanner({required this.message, required this.isError});

  @override
  Widget build(BuildContext context) {
    final color =
        isError ? const Color(0xFFEF4444) : const Color(0xFF22C55E);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const _Card(
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 40),
          const SizedBox(height: 12),
          Text(
            'Failed to load profile: $message',
            style: const TextStyle(color: Colors.white54),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
