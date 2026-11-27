import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driveops_management/features/admin/presentation/providers/admin_providers.dart';
import 'package:driveops_management/services/admin_api_service.dart';
import 'package:driveops_management/services/exceptions.dart';
import 'package:driveops_management/shared/dtos/requests/admin_requests.dart';
import 'package:driveops_management/shared/models/admin_account.dart';

class AdminFareSettingsScreen extends ConsumerStatefulWidget {
  const AdminFareSettingsScreen({super.key});

  @override
  ConsumerState<AdminFareSettingsScreen> createState() =>
      _AdminFareSettingsScreenState();
}

class _AdminFareSettingsScreenState
    extends ConsumerState<AdminFareSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _baseFare = TextEditingController();
  final _perKm = TextEditingController();
  final _perMinute = TextEditingController();
  final _premium = TextEditingController();
  final _shared = TextEditingController();

  bool _prefilled = false;
  bool _saving = false;
  String? _error;
  String _currency = 'EUR';

  @override
  void dispose() {
    _baseFare.dispose();
    _perKm.dispose();
    _perMinute.dispose();
    _premium.dispose();
    _shared.dispose();
    super.dispose();
  }

  void _prefill(FareSettings settings) {
    if (_prefilled) return;
    _prefilled = true;
    _baseFare.text = settings.baseFare.toStringAsFixed(2);
    _perKm.text = settings.perKmRate.toStringAsFixed(2);
    _perMinute.text = settings.perMinuteRate.toStringAsFixed(2);
    _premium.text = settings.premiumMultiplier.toStringAsFixed(2);
    _shared.text = settings.sharedMultiplier.toStringAsFixed(2);
    _currency = settings.currency;
  }

  String? _validateAmount(String? value, {bool allowZero = true}) {
    final v = value?.trim() ?? '';
    final parsed = double.tryParse(v);
    if (parsed == null) return 'Enter a number';
    if (parsed < 0) return 'Cannot be negative';
    if (!allowZero && parsed == 0) return 'Must be greater than 0';
    return null;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final updated = await ref.read(adminApiServiceProvider).updateFareSettings(
            UpdateFareSettingsPayload(
              baseFare: double.parse(_baseFare.text.trim()),
              perKmRate: double.parse(_perKm.text.trim()),
              perMinuteRate: double.parse(_perMinute.text.trim()),
              premiumMultiplier: double.parse(_premium.text.trim()),
              sharedMultiplier: double.parse(_shared.text.trim()),
            ),
          );
      _prefilled = false;
      _prefill(updated);
      ref.invalidate(fareSettingsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fare settings saved'),
            backgroundColor: Color(0xFF22C55E),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e is ApiException ? e.message : e.toString();
        });
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(fareSettingsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Fare Settings',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'These values drive trip estimates and the final fare charged for '
              'completed trips. Changes apply immediately.',
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 24),
            settingsAsync.when(
              data: (settings) {
                _prefill(settings);
                return _buildForm();
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(40),
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
                ),
              ),
              error: (e, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e is ApiException ? e.message : 'Failed to load fare settings',
                    style: const TextStyle(color: Color(0xFFEF4444)),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => ref.invalidate(fareSettingsProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 560),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF252538),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _field(_baseFare, 'Base fare', allowZero: true),
                const SizedBox(width: 16),
                _field(_perKm, 'Per km rate', allowZero: true),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _field(_perMinute, 'Per minute rate', allowZero: true),
                const SizedBox(width: 16),
                _field(_premium, 'Premium multiplier', allowZero: false),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _field(_shared, 'Shared multiplier', allowZero: false),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Charging currency',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A2E),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _currency,
                          style: const TextStyle(color: Colors.white54),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _saving
                      ? null
                      : () => ref.invalidate(fareSettingsProvider),
                  child: const Text('Reload',
                      style: TextStyle(color: Colors.white54)),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save, size: 18),
                  label: Text(_saving ? 'Saving…' : 'Save changes'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController controller, String label,
      {required bool allowZero}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF1A1A2E),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
            validator: (value) => _validateAmount(value, allowZero: allowZero),
          ),
        ],
      ),
    );
  }
}
