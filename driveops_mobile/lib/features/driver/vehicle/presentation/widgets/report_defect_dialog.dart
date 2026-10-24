import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driveops_mobile/shared/dtos/requests/vehicle_requests.dart';
import 'package:driveops_mobile/shared/models/vehicle.dart';
import 'package:driveops_mobile/shared/providers/repository_providers.dart';

/// Dialog for reporting a vehicle defect (persists via POST /api/vehicle/{id}/defects).
class ReportDefectDialog extends ConsumerStatefulWidget {
  final Vehicle vehicle;

  const ReportDefectDialog({super.key, required this.vehicle});

  @override
  ConsumerState<ReportDefectDialog> createState() => _ReportDefectDialogState();
}

class _ReportDefectDialogState extends ConsumerState<ReportDefectDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DefectSeverity _severity = DefectSeverity.medium;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final driverId = widget.vehicle.assignedDriverId;
    if (driverId == null) {
      setState(() => _error = 'This vehicle has no assigned driver.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = ref.read(vehicleRepositoryProvider);
      await repo.reportDefect(
        widget.vehicle.id,
        ReportVehicleDefectRequest(
          driverId: driverId,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          severity: _severity,
        ),
      );

      // Refresh the "Defect Reports" section on the vehicle tab.
      ref.invalidate(vehicleDefectsProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Defect reported. Dispatch has been notified.'),
            backgroundColor: Color(0xFF22C55E),
          ),
        );
      }
    } catch (e) {
      setState(() => _error = 'Failed to report defect: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.report_problem_outlined,
                      color: Color(0xFFEF4444), size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Report Defect — ${widget.vehicle.internalName ?? widget.vehicle.licensePlate}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _titleController,
                style: const TextStyle(color: Colors.white),
                decoration: _decoration('Title', 'e.g. Cracked windshield'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                style: const TextStyle(color: Colors.white),
                decoration: _decoration(
                    'Description', 'Describe the defect in detail...'),
                maxLines: 4,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Description is required'
                    : null,
              ),
              const SizedBox(height: 16),
              const Text('Severity',
                  style: TextStyle(color: Colors.white54, fontSize: 13)),
              const SizedBox(height: 8),
              DropdownButtonFormField<DefectSeverity>(
                initialValue: _severity,
                dropdownColor: const Color(0xFF252538),
                decoration: _decoration(null, null),
                items: DefectSeverity.values
                    .map((s) =>
                        DropdownMenuItem(value: s, child: Text(s.label)))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _severity = v ?? DefectSeverity.medium),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!,
                    style: const TextStyle(
                        color: Color(0xFFEF4444), fontSize: 13)),
              ],
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed:
                        _isLoading ? null : () => Navigator.pop(context),
                    child: const Text('Cancel',
                        style: TextStyle(color: Colors.white54)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Submit Report'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration(String? label, String? hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: Colors.white54),
      hintStyle: const TextStyle(color: Colors.white24),
      filled: true,
      fillColor: const Color(0xFF252538),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }
}
