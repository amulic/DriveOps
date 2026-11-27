import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driveops_management/shared/dtos/requests/vehicle_requests.dart';
import 'package:driveops_management/shared/models/vehicle.dart';
import 'package:driveops_management/shared/providers/repository_providers.dart';
import 'package:driveops_management/features/vehicles/presentation/providers/vehicles_providers.dart';
import 'package:driveops_management/services/exceptions.dart';

/// Records a single vehicle service/inspection without overwriting prior records.
class RecordServiceDialog extends ConsumerStatefulWidget {
  final Vehicle vehicle;

  const RecordServiceDialog({super.key, required this.vehicle});

  @override
  ConsumerState<RecordServiceDialog> createState() => _RecordServiceDialogState();
}

class _RecordServiceDialogState extends ConsumerState<RecordServiceDialog> {
  static const _serviceTypes = [
    'RoutineMaintenance',
    'Inspection',
    'Repair',
    'Other',
  ];

  final _formKey = GlobalKey<FormState>();
  final _odometerController = TextEditingController();
  final _costController = TextEditingController();
  final _performedByController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _serviceType = 'RoutineMaintenance';
  DateTime _serviceDate = DateTime.now();
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final mileage = widget.vehicle.mileage;
    if (mileage != null) {
      _odometerController.text = mileage.toStringAsFixed(1);
    }
  }

  @override
  void dispose() {
    _odometerController.dispose();
    _costController.dispose();
    _performedByController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _serviceDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 10)),
      lastDate: DateTime.now(),
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
      setState(() => _serviceDate = date);
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final odometer = _odometerController.text.trim().isEmpty
          ? null
          : double.parse(_odometerController.text.trim());
      final cost = _costController.text.trim().isEmpty
          ? null
          : double.parse(_costController.text.trim());

      await ref.read(vehicleRepositoryProvider).addServiceRecord(
            widget.vehicle.id,
            CreateVehicleServiceRecordRequest(
              serviceDate: _serviceDate,
              serviceType: _serviceType,
              description: _descriptionController.text.trim(),
              performedBy: _performedByController.text.trim(),
              odometerKm: odometer,
              cost: cost,
            ),
          );

      ref.invalidate(vehiclesAsyncProvider);
      ref.invalidate(filteredVehiclesProvider);
      ref.invalidate(allVehiclesProvider);
      ref.invalidate(vehiclesNeedingServiceProvider);
      ref.invalidate(vehicleServiceRecordsProvider(widget.vehicle.id));
      ref.invalidate(vehicleServiceRemindersProvider);

      if (mounted) Navigator.of(context).pop(true);
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
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.build_circle_outlined,
                          color: Color(0xFF3B82F6)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Record Service — ${widget.vehicle.licensePlate}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: Colors.white54),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _label('Service Type'),
                  DropdownButtonFormField<String>(
                    initialValue: _serviceType,
                    dropdownColor: const Color(0xFF252538),
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration(),
                    items: _serviceTypes
                        .map((t) => DropdownMenuItem<String>(
                              value: t,
                              child: Text(_typeLabel(t)),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _serviceType = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  _label('Service Date'),
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF252538),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${_serviceDate.month}/${_serviceDate.day}/${_serviceDate.year}',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          const Icon(Icons.calendar_today,
                              color: Colors.white54, size: 18),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('Odometer (km)'),
                            TextFormField(
                              controller: _odometerController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9.]')),
                              ],
                              style: const TextStyle(color: Colors.white),
                              decoration: _inputDecoration(hint: 'e.g. 45200.5'),
                              validator: _validateNumber,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('Cost'),
                            TextFormField(
                              controller: _costController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9.]')),
                              ],
                              style: const TextStyle(color: Colors.white),
                              decoration: _inputDecoration(hint: 'e.g. 120.00'),
                              validator: _validateNumber,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _label('Performed By'),
                  TextFormField(
                    controller: _performedByController,
                    style: const TextStyle(color: Colors.white),
                    decoration:
                        _inputDecoration(hint: 'e.g. Partner Garage Mostar'),
                  ),
                  const SizedBox(height: 12),
                  _label('Description'),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration(
                        hint: 'Work performed, parts replaced...'),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: const TextStyle(
                          color: Color(0xFFEF4444), fontSize: 13),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: const Text('Cancel',
                            style: TextStyle(color: Colors.white70)),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Save Record'),
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

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white24),
      filled: true,
      fillColor: const Color(0xFF252538),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  String? _validateNumber(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final parsed = double.tryParse(text);
    if (parsed == null || parsed < 0) return 'Invalid number';
    return null;
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'Inspection':
        return 'Inspection';
      case 'Repair':
        return 'Repair';
      case 'Other':
        return 'Other';
      case 'RoutineMaintenance':
      default:
        return 'Routine maintenance';
    }
  }
}
