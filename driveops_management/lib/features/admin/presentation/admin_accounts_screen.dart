import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driveops_management/features/admin/presentation/providers/admin_providers.dart';
import 'package:driveops_management/services/admin_api_service.dart';
import 'package:driveops_management/services/exceptions.dart';
import 'package:driveops_management/shared/dtos/requests/admin_requests.dart';
import 'package:driveops_management/shared/models/admin_account.dart';

const _appRoles = ['admin', 'dispatcher', 'driver', 'customer'];

class AdminAccountsScreen extends ConsumerStatefulWidget {
  const AdminAccountsScreen({super.key});

  @override
  ConsumerState<AdminAccountsScreen> createState() =>
      _AdminAccountsScreenState();
}

class _AdminAccountsScreenState extends ConsumerState<AdminAccountsScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _query = value.trim());
    });
  }

  void _refresh() => ref.invalidate(adminAccountsProvider(_query));

  String _errorMessage(Object e) {
    if (e is ApiException) return e.message;
    return e.toString();
  }

  Future<void> _showCreateDialog() async {
    final created = await showDialog<AdminAccount>(
      context: context,
      builder: (_) => const _CreateAccountDialog(),
    );
    if (created != null) {
      _refresh();
      _snack('Account "${created.username}" created');
    }
  }

  Future<void> _editRoles(AdminAccount account) async {
    final roles = await showDialog<List<String>>(
      context: context,
      builder: (_) => _RolesDialog(account: account),
    );
    if (roles == null) return;
    try {
      await ref.read(adminApiServiceProvider).setRoles(account.id, roles);
      _refresh();
      _snack('Roles updated for ${account.username}');
    } catch (e) {
      _snack(_errorMessage(e), isError: true);
    }
  }

  Future<void> _toggleEnabled(AdminAccount account) async {
    try {
      await ref.read(adminApiServiceProvider).updateAccount(
            account.id,
            UpdateAccountPayload(enabled: !account.enabled),
          );
      _refresh();
      _snack('${account.username} ${account.enabled ? 'disabled' : 'enabled'}');
    } catch (e) {
      _snack(_errorMessage(e), isError: true);
    }
  }

  Future<void> _resetPassword(AdminAccount account) async {
    final password = await showDialog<String>(
      context: context,
      builder: (_) => _ResetPasswordDialog(account: account),
    );
    if (password == null) return;
    try {
      await ref.read(adminApiServiceProvider).resetPassword(account.id, password);
      _snack('Temporary password set for ${account.username}');
    } catch (e) {
      _snack(_errorMessage(e), isError: true);
    }
  }

  void _snack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? const Color(0xFFEF4444) : const Color(0xFF22C55E),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(adminAccountsProvider(_query));

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Row(
              children: [
                const Text(
                  'Accounts & Roles',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: _showCreateDialog,
                  icon: const Icon(Icons.person_add_alt_1, size: 18),
                  label: const Text('Create Account'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF3B82F6),
                    side: const BorderSide(color: Color(0xFF3B82F6)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            child: SizedBox(
              width: 360,
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search by name, username or email…',
                  hintStyle: const TextStyle(color: Colors.white38),
                  prefixIcon:
                      const Icon(Icons.search, color: Colors.white54),
                  filled: true,
                  fillColor: const Color(0xFF252538),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: accountsAsync.when(
              data: (accounts) => _buildTable(accounts),
              loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
              ),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        color: Color(0xFFEF4444), size: 40),
                    const SizedBox(height: 12),
                    Text(_errorMessage(e),
                        style: const TextStyle(color: Colors.white54)),
                    const SizedBox(height: 12),
                    OutlinedButton(onPressed: _refresh, child: const Text('Retry')),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(List<AdminAccount> accounts) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Card(
        color: const Color(0xFF252538),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: SingleChildScrollView(
          child: SizedBox(
            width: double.infinity,
            child: DataTable(
              columnSpacing: 20,
              horizontalMargin: 20,
              columns: const [
                DataColumn(label: Text('Account')),
                DataColumn(label: Text('Email')),
                DataColumn(label: Text('Roles')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('')),
              ],
              rows: accounts.map((account) {
                return DataRow(cells: [
                  DataCell(Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(account.displayName,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500)),
                      Text('@${account.username}',
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12)),
                    ],
                  )),
                  DataCell(Text(account.email ?? '—',
                      style: const TextStyle(color: Colors.white70))),
                  DataCell(_buildRoleChips(account.roles)),
                  DataCell(_buildStatusChip(account.enabled)),
                  DataCell(_buildActions(account)),
                ]);
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleChips(List<String> roles) {
    if (roles.isEmpty) {
      return const Text('—', style: TextStyle(color: Colors.white38));
    }
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: roles
          .map((role) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(role,
                    style: const TextStyle(
                        color: Color(0xFF3B82F6), fontSize: 11)),
              ))
          .toList(),
    );
  }

  Widget _buildStatusChip(bool enabled) {
    final color =
        enabled ? const Color(0xFF22C55E) : const Color(0xFFEF4444);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(enabled ? 'Enabled' : 'Disabled',
          style: TextStyle(color: color, fontSize: 12)),
    );
  }

  Widget _buildActions(AdminAccount account) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.white54),
      color: const Color(0xFF252538),
      onSelected: (value) {
        switch (value) {
          case 'roles':
            _editRoles(account);
          case 'toggle':
            _toggleEnabled(account);
          case 'password':
            _resetPassword(account);
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: 'roles',
          child: Row(children: [
            Icon(Icons.shield_outlined, color: Colors.white54, size: 18),
            SizedBox(width: 8),
            Text('Edit roles', style: TextStyle(color: Colors.white)),
          ]),
        ),
        PopupMenuItem(
          value: 'toggle',
          child: Row(children: [
            Icon(account.enabled ? Icons.block : Icons.check_circle_outline,
                color: Colors.white54, size: 18),
            const SizedBox(width: 8),
            Text(account.enabled ? 'Disable account' : 'Enable account',
                style: const TextStyle(color: Colors.white)),
          ]),
        ),
        const PopupMenuItem(
          value: 'password',
          child: Row(children: [
            Icon(Icons.key_outlined, color: Colors.white54, size: 18),
            SizedBox(width: 8),
            Text('Reset password', style: TextStyle(color: Colors.white)),
          ]),
        ),
      ],
    );
  }
}

class _CreateAccountDialog extends ConsumerStatefulWidget {
  const _CreateAccountDialog();

  @override
  ConsumerState<_CreateAccountDialog> createState() =>
      _CreateAccountDialogState();
}

class _CreateAccountDialogState extends ConsumerState<_CreateAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _roles = <String>{'dispatcher'};
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final account = await ref.read(adminApiServiceProvider).createAccount(
            CreateAccountPayload(
              username: _username.text.trim(),
              firstName: _firstName.text.trim(),
              lastName: _lastName.text.trim(),
              email: _email.text.trim(),
              temporaryPassword: _password.text,
              roles: _roles.toList(),
            ),
          );
      if (mounted) Navigator.of(context).pop(account);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e is ApiException ? e.message : e.toString();
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A2E),
      title: const Text('Create Account', style: TextStyle(color: Colors.white)),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field(_username, 'Username', required: true),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _field(_firstName, 'First name')),
                  const SizedBox(width: 12),
                  Expanded(child: _field(_lastName, 'Last name')),
                ]),
                const SizedBox(height: 12),
                _field(_email, 'Email', email: true),
                const SizedBox(height: 12),
                _field(_password, 'Temporary password',
                    required: true, minLength: 8),
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Roles',
                      style: TextStyle(color: Colors.white54, fontSize: 12)),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: _appRoles
                      .map((role) => FilterChip(
                            label: Text(role),
                            selected: _roles.contains(role),
                            onSelected: (selected) => setState(() {
                              selected
                                  ? _roles.add(role)
                                  : _roles.remove(role);
                            }),
                          ))
                      .toList(),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!,
                      style: const TextStyle(
                          color: Color(0xFFEF4444), fontSize: 13)),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: Text(_saving ? 'Creating…' : 'Create'),
        ),
      ],
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = false,
    bool email = false,
    int? minLength,
  }) {
    return TextFormField(
      controller: controller,
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
      validator: (value) {
        final v = value?.trim() ?? '';
        if (required && v.isEmpty) return 'Required';
        if (email && v.isNotEmpty &&
            !RegExp(r'^[\w\.\-]+@[\w\.\-]+\.\w{2,}$').hasMatch(v)) {
          return 'Enter a valid email address';
        }
        if (minLength != null && v.isNotEmpty && v.length < minLength) {
          return 'At least $minLength characters';
        }
        return null;
      },
    );
  }
}

class _RolesDialog extends StatefulWidget {
  final AdminAccount account;

  const _RolesDialog({required this.account});

  @override
  State<_RolesDialog> createState() => _RolesDialogState();
}

class _RolesDialogState extends State<_RolesDialog> {
  late final Set<String> _roles = widget.account.roles.toSet();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A2E),
      title: Text('Roles — ${widget.account.username}',
          style: const TextStyle(color: Colors.white, fontSize: 18)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: _appRoles
            .map((role) => CheckboxListTile(
                  value: _roles.contains(role),
                  title: Text(role, style: const TextStyle(color: Colors.white)),
                  activeColor: const Color(0xFF3B82F6),
                  onChanged: (checked) => setState(() {
                    checked == true ? _roles.add(role) : _roles.remove(role);
                  }),
                ))
            .toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_roles.toList()),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _ResetPasswordDialog extends StatefulWidget {
  final AdminAccount account;

  const _ResetPasswordDialog({required this.account});

  @override
  State<_ResetPasswordDialog> createState() => _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends State<_ResetPasswordDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A2E),
      title: Text('Reset password — ${widget.account.username}',
          style: const TextStyle(color: Colors.white, fontSize: 18)),
      content: TextField(
        controller: _controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: 'Temporary password',
          labelStyle: const TextStyle(color: Colors.white54),
          errorText: _error,
          filled: true,
          fillColor: const Color(0xFF252538),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
        ),
        FilledButton(
          onPressed: () {
            if (_controller.text.length < 8) {
              setState(() => _error = 'At least 8 characters');
              return;
            }
            Navigator.of(context).pop(_controller.text);
          },
          child: const Text('Set password'),
        ),
      ],
    );
  }
}
