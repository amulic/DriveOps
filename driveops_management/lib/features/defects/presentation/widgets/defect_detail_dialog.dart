import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driveops_management/shared/models/defect_report.dart';
import 'package:driveops_management/shared/providers/repository_providers.dart';
import 'package:driveops_management/features/defects/presentation/providers/defects_providers.dart';
import 'package:driveops_management/features/defects/presentation/widgets/defect_chips.dart';
import 'package:driveops_management/features/defects/presentation/widgets/resolve_defect_dialog.dart';
import 'package:driveops_management/features/drivers/presentation/widgets/driver_detail_dialog.dart';

class DefectDetailDialog extends ConsumerWidget {
  final DefectReport defect;

  const DefectDetailDialog({super.key, required this.defect});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    DefectSeverityChip(severity: defect.severity),
                    const SizedBox(width: 8),
                    DefectStatusChip(status: defect.status),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white54),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  defect.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                _buildInfoSection('Vehicle & Reporter', [
                  _buildInfoRow(Icons.directions_car_outlined, defect.vehicleLabel),
                  _buildReporterRow(context, ref),
                ]),
                const SizedBox(height: 16),
                _buildInfoSection('Description', [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        defect.description,
                        style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 16),
                _buildInfoSection('Timeline', [
                  _buildInfoRow(Icons.report_outlined, 'Reported: ${_formatDateTime(defect.reportedAt)}'),
                  if (defect.resolvedAt != null)
                    _buildInfoRow(Icons.check_circle_outline, 'Resolved: ${_formatDateTime(defect.resolvedAt!)}'),
                ]),
                if (defect.resolutionNotes != null && defect.resolutionNotes!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildInfoSection('Resolution Notes', [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          defect.resolutionNotes!,
                          style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
                        ),
                      ),
                    ),
                  ]),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    if (defect.isOpen)
                      Expanded(
                        child: _buildActionButton(
                          label: 'Resolve',
                          icon: Icons.check_circle_outline,
                          color: const Color(0xFF22C55E),
                          onTap: () => _resolve(context),
                        ),
                      )
                    else
                      Expanded(
                        child: _buildActionButton(
                          label: 'Reopen',
                          icon: Icons.replay,
                          color: const Color(0xFFF59E0B),
                          onTap: () => _reopen(context, ref),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReporterRow(BuildContext context, WidgetRef ref) {
    final name = defect.driverName ?? 'Unknown driver';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.person_outlined, size: 16, color: Colors.white38),
          const SizedBox(width: 10),
          Expanded(
            child: InkWell(
              onTap: () => _openDriver(context, ref),
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: const TextStyle(
                          color: Color(0xFF3B82F6),
                          fontSize: 14,
                          decoration: TextDecoration.underline,
                          decorationColor: Color(0xFF3B82F6),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.open_in_new, size: 13, color: Color(0xFF3B82F6)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openDriver(BuildContext context, WidgetRef ref) async {
    try {
      final driver = await ref.read(driverRepositoryProvider).getDriverById(defect.driverId);
      if (!context.mounted) return;
      if (driver == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Driver profile not found'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
        return;
      }
      showDialog(
        context: context,
        builder: (context) => DriverDetailDialog(driver: driver),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load driver: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<void> _resolve(BuildContext context) async {
    final resolved = await showDialog<bool>(
      context: context,
      builder: (context) => ResolveDefectDialog(defect: defect),
    );
    // The defect is stale after a successful resolve — close the detail view;
    // providers were already invalidated by DefectActions.
    if (resolved == true && context.mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _reopen(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reopen Defect', style: TextStyle(color: Colors.white)),
        content: Text(
          'Reopen "${defect.title}"? It will appear as an open report again.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFF59E0B)),
            child: const Text('Reopen'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(defectActionsProvider).reopen(defect.id);
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${defect.title}" reopened'),
            backgroundColor: const Color(0xFFF59E0B),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reopen: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Widget _buildInfoSection(String title, List<Widget> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF3B82F6)),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF252538),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(children: rows),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white38),
          const SizedBox(width: 10),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 13)),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.5)),
        padding: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${date.month}/${date.day}/${date.year} ${two(date.hour)}:${two(date.minute)}';
  }
}
