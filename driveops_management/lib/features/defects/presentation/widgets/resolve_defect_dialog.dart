import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driveops_management/shared/models/defect_report.dart';
import 'package:driveops_management/features/defects/presentation/providers/defects_providers.dart';

class ResolveDefectDialog extends ConsumerStatefulWidget {
  final DefectReport defect;

  const ResolveDefectDialog({super.key, required this.defect});

  @override
  ConsumerState<ResolveDefectDialog> createState() => _ResolveDefectDialogState();
}

class _ResolveDefectDialogState extends ConsumerState<ResolveDefectDialog> {
  final _notesController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _resolve() async {
    setState(() => _submitting = true);
    try {
      final notes = _notesController.text.trim();
      await ref.read(defectActionsProvider).resolve(
            widget.defect.id,
            notes.isEmpty ? null : notes,
          );
      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${widget.defect.title}" marked as resolved'),
            backgroundColor: const Color(0xFF22C55E),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to resolve: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Resolve Defect', style: TextStyle(color: Colors.white)),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.defect.title,
              style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              widget.defect.vehicleLabel,
              style: const TextStyle(color: Colors.white38, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              maxLines: 3,
              maxLength: 1000,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Resolution notes (optional)',
                labelStyle: const TextStyle(color: Colors.white54),
                hintText: 'e.g. Brake pads replaced at partner garage',
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: const Color(0xFF252538),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
        ),
        FilledButton.icon(
          onPressed: _submitting ? null : _resolve,
          icon: _submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.check_circle_outline, size: 18),
          label: const Text('Resolve'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF22C55E),
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
