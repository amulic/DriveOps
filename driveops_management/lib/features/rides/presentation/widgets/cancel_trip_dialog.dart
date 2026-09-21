import 'package:flutter/material.dart';

/// Confirm dialog to cancel a trip, with an optional reason field.
/// Returns the reason (empty string when left blank) when confirmed, null when dismissed.
class CancelTripDialog extends StatefulWidget {
  const CancelTripDialog({super.key});

  static Future<String?> show(BuildContext context) {
    return showDialog<String?>(
      context: context,
      builder: (_) => const CancelTripDialog(),
    );
  }

  @override
  State<CancelTripDialog> createState() => _CancelTripDialogState();
}

class _CancelTripDialogState extends State<CancelTripDialog> {
  final TextEditingController _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF252538),
      title: const Text('Cancel Ride', style: TextStyle(color: Colors.white)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Are you sure you want to cancel this ride?',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _reasonController,
            style: const TextStyle(color: Colors.white),
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Reason (optional)',
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: const Color(0xFF1A1A2E),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Keep Ride', style: TextStyle(color: Colors.white54)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
          onPressed: () => Navigator.of(context).pop(_reasonController.text.trim()),
          child: const Text('Cancel Ride'),
        ),
      ],
    );
  }
}
