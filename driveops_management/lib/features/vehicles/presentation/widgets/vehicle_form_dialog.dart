import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driveops_management/shared/models/vehicle.dart';
import 'package:driveops_management/shared/dtos/requests/vehicle_requests.dart';
import 'package:driveops_management/shared/providers/repository_providers.dart';
import 'package:driveops_management/services/exceptions.dart';
import 'package:driveops_management/features/vehicles/presentation/providers/vehicles_providers.dart';

class VehicleFormDialog extends ConsumerStatefulWidget {
  final Vehicle? vehicle;

  const VehicleFormDialog({super.key, this.vehicle});

  bool get isEdit => vehicle != null;

  @override
  ConsumerState<VehicleFormDialog> createState() => _VehicleFormDialogState();
}

class _VehicleFormDialogState extends ConsumerState<VehicleFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _licensePlateController;
  late final TextEditingController _makeController;
  late final TextEditingController _modelController;
  late final TextEditingController _yearController;
  late final TextEditingController _colorController;
  late final TextEditingController _vinController;
  late final TextEditingController _insurancePolicyController;
  late final TextEditingController _seatingCapacityController;

  late FuelType _fuelType;
  DateTime? _insuranceExpiryDate;
  DateTime? _registrationExpiryDate;

  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final vehicle = widget.vehicle;
    _licensePlateController =
        TextEditingController(text: vehicle?.licensePlate ?? '');
    _makeController = TextEditingController(text: vehicle?.make ?? '');
    _modelController = TextEditingController(text: vehicle?.model ?? '');
    _yearController = TextEditingController(
      text: vehicle?.year.toString() ?? DateTime.now().year.toString(),
    );
    _colorController = TextEditingController(text: vehicle?.color ?? '');
    _vinController = TextEditingController(text: vehicle?.vin ?? '');
    _insurancePolicyController =
        TextEditingController(text: vehicle?.insurancePolicyNumber ?? '');
    _seatingCapacityController = TextEditingController(
      text: vehicle?.seatingCapacity?.toString() ?? '',
    );
    _fuelType = vehicle?.fuelType ?? FuelType.petrol;
    _insuranceExpiryDate = vehicle?.insuranceExpiryDate;
    _registrationExpiryDate = vehicle?.registrationExpiryDate;
  }

  @override
  void dispose() {
    _licensePlateController.dispose();
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _colorController.dispose();
    _vinController.dispose();
    _insurancePolicyController.dispose();
    _seatingCapacityController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({
    required DateTime? current,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: current ?? now.add(const Duration(days: 365)),
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 20),
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
    if (date != null) onPicked(date);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_insuranceExpiryDate == null || _registrationExpiryDate == null) {
      setState(() => _error =
          'Please select both insurance and registration expiry dates.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = ref.read(vehicleRepositoryProvider);
      final year = int.parse(_yearController.text.trim());
      final seats = _seatingCapacityController.text.trim().isEmpty
          ? null
          : int.parse(_seatingCapacityController.text.trim());
      final insuranceExpiry = _insuranceExpiryDate!;
      final registrationExpiry = _registrationExpiryDate!;

      final Vehicle saved;
      if (widget.isEdit) {
        saved = await repo.updateVehicle(
          widget.vehicle!.id,
          UpdateVehicleRequest(
            licensePlate: _licensePlateController.text.trim(),
            make: _makeController.text.trim(),
            model: _modelController.text.trim(),
            year: year,
            vin: _vinController.text.trim(),
            color: _colorController.text.trim(),
            insurancePolicyNumber: _insurancePolicyController.text.trim(),
            insuranceExpiryDate: insuranceExpiry,
            registrationExpiryDate: registrationExpiry,
            fuelType: _fuelType.toInt(),
            seatingCapacity: seats,
          ),
        );
      } else {
        saved = await repo.createVehicle(
          CreateVehicleRequest(
            licensePlate: _licensePlateController.text.trim(),
            make: _makeController.text.trim(),
            model: _modelController.text.trim(),
            year: year,
            color: _colorController.text.trim(),
            vin: _vinController.text.trim(),
            insurancePolicyNumber: _insurancePolicyController.text.trim(),
            insuranceExpiryDate: insuranceExpiry,
            registrationExpiryDate: registrationExpiry,
            fuelType: _fuelType.toInt(),
            seatingCapacity: seats,
          ),
        );
      }

      ref.invalidate(vehiclesAsyncProvider);
      ref.invalidate(filteredVehiclesProvider);
      ref.invalidate(allVehiclesProvider);
      ref.invalidate(vehiclesNeedingServiceProvider);

      if (mounted) Navigator.of(context).pop(saved);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e is ApiException ? e.message : e.toString();
        });
      }
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
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _licensePlateController,
                          label: 'License Plate',
                          hint: 'e.g. A12-M-345',
                          textCapitalization: TextCapitalization.characters,
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Required'
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          controller: _yearController,
                          label: 'Year',
                          hint: 'e.g. 2022',
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: _validateYear,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _makeController,
                          label: 'Make',
                          hint: 'e.g. Toyota',
                          textCapitalization: TextCapitalization.words,
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Required'
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          controller: _modelController,
                          label: 'Model',
                          hint: 'e.g. Camry',
                          textCapitalization: TextCapitalization.words,
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Required'
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _colorController,
                          label: 'Color',
                          hint: 'e.g. White',
                          textCapitalization: TextCapitalization.words,
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Required'
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          controller: _vinController,
                          label: 'VIN',
                          hint: 'e.g. 1HGCM82633A004352',
                          textCapitalization: TextCapitalization.characters,
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Required'
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _insurancePolicyController,
                    label: 'Insurance Policy Number',
                    hint: 'e.g. POL-2026-00123',
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildFuelDropdown(),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          controller: _seatingCapacityController,
                          label: 'Seating Capacity (optional)',
                          hint: 'e.g. 4',
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: _validateSeats,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateField(
                          label: 'Insurance Expiry',
                          value: _insuranceExpiryDate,
                          onTap: () => _pickDate(
                            current: _insuranceExpiryDate,
                            onPicked: (d) =>
                                setState(() => _insuranceExpiryDate = d),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDateField(
                          label: 'Registration Expiry',
                          value: _registrationExpiryDate,
                          onTap: () => _pickDate(
                            current: _registrationExpiryDate,
                            onPicked: (d) =>
                                setState(() => _registrationExpiryDate = d),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_insuranceExpiryDate == null)
                    _buildFieldError('Insurance expiry is required'),
                  if (_registrationExpiryDate == null)
                    _buildFieldError('Registration expiry is required'),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          color: Color(0xFFEF4444),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed:
                            _isLoading ? null : () => Navigator.of(context).pop(),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
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
                            : Text(widget.isEdit ? 'Save Changes' : 'Create Vehicle'),
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

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          widget.isEdit ? 'Edit Vehicle' : 'Add New Vehicle',
          style: const TextStyle(
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
    );
  }

  Widget _buildFuelDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Fuel Type',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<FuelType>(
          initialValue: _fuelType,
          dropdownColor: const Color(0xFF252538),
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF252538),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          items: FuelType.values
              .map((f) => DropdownMenuItem<FuelType>(
                    value: f,
                    child: Text(_fuelLabel(f)),
                  ))
              .toList(),
          onChanged: (value) {
            if (value != null) setState(() => _fuelType = value);
          },
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
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

  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
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
                        : 'Select date',
                    style: TextStyle(
                      color: value != null ? Colors.white : Colors.white24,
                    ),
                  ),
                ),
                const Icon(Icons.calendar_today,
                    color: Colors.white54, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFieldError(String message) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        message,
        style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12),
      ),
    );
  }

  String? _validateYear(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Required';
    final year = int.tryParse(text);
    if (year == null) return 'Invalid year';
    final maxYear = DateTime.now().year + 1;
    if (year < 1980 || year > maxYear) return '1980-$maxYear';
    return null;
  }

  String? _validateSeats(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final seats = int.tryParse(text);
    if (seats == null || seats < 1 || seats > 20) return '1-20';
    return null;
  }

  String _fuelLabel(FuelType fuel) {
    return fuel.name[0].toUpperCase() + fuel.name.substring(1);
  }
}
