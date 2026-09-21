import 'package:flutter/material.dart';
import 'package:driveops_mobile/features/driver/history/presentation/driver_history_screen.dart';
import 'package:driveops_mobile/shared/models/trip.dart';

/// Filter dialog for the ride history list: status, date range, free text.
class TripFilterDialog extends StatefulWidget {
  final TripFilter current;

  const TripFilterDialog({super.key, required this.current});

  @override
  State<TripFilterDialog> createState() => _TripFilterDialogState();
}

class _TripFilterDialogState extends State<TripFilterDialog> {
  late TripStatus? _status = widget.current.status;
  late DateTime? _from = widget.current.from;
  late DateTime? _to = widget.current.to;
  late final TextEditingController _queryController =
      TextEditingController(text: widget.current.query);

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final initial = (isFrom ? _from : _to) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF3B82F6),
            surface: Color(0xFF1A1A2E),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => isFrom ? _from = picked : _to = picked);
    }
  }

  String _fmtDate(DateTime? d) =>
      d == null ? 'Any' : '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter Rides',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            const Text('Status',
                style: TextStyle(color: Colors.white54, fontSize: 13)),
            const SizedBox(height: 8),
            DropdownButtonFormField<TripStatus?>(
              initialValue: _status,
              dropdownColor: const Color(0xFF252538),
              decoration: _inputDecoration(),
              items: [
                const DropdownMenuItem(value: null, child: Text('All statuses')),
                ...TripStatus.values.map((s) => DropdownMenuItem(
                      value: s,
                      child: Text(_statusLabel(s)),
                    )),
              ],
              onChanged: (v) => setState(() => _status = v),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _dateField('From', _from, () => _pickDate(isFrom: true),
                      () => setState(() => _from = null)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _dateField('To', _to, () => _pickDate(isFrom: false),
                      () => setState(() => _to = null)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Search',
                style: TextStyle(color: Colors.white54, fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
              controller: _queryController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration().copyWith(
                hintText: 'Address or customer name...',
                hintStyle: const TextStyle(color: Colors.white24),
                prefixIcon:
                    const Icon(Icons.search, color: Colors.white38, size: 20),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                TextButton(
                  onPressed: () =>
                      Navigator.pop(context, const TripFilter()),
                  child: const Text('Clear all',
                      style: TextStyle(color: Colors.white54)),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel',
                      style: TextStyle(color: Colors.white54)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      TripFilter(
                        status: _status,
                        from: _from,
                        to: _to,
                        query: _queryController.text.trim(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Apply'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
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

  Widget _dateField(
      String label, DateTime? value, VoidCallback onTap, VoidCallback onClear) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 13)),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF252538),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _fmtDate(value),
                    style: TextStyle(
                      color: value == null ? Colors.white24 : Colors.white,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (value != null)
                  GestureDetector(
                    onTap: onClear,
                    child: const Icon(Icons.close,
                        size: 16, color: Colors.white38),
                  )
                else
                  const Icon(Icons.calendar_today,
                      size: 16, color: Colors.white38),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _statusLabel(TripStatus s) => switch (s) {
        TripStatus.requested => 'Requested',
        TripStatus.assigned => 'Assigned',
        TripStatus.driverEnRoute => 'Driver en route',
        TripStatus.inProgress => 'In progress',
        TripStatus.completed => 'Completed',
        TripStatus.cancelled => 'Cancelled',
        TripStatus.noDriverAvailable => 'No driver available',
        TripStatus.declined => 'Declined',
      };
}
