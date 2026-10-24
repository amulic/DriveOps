import 'package:flutter/material.dart';
import 'package:driveops_management/shared/models/defect_report.dart';

Color defectSeverityColor(DefectSeverity severity) {
  switch (severity) {
    case DefectSeverity.low:
      return const Color(0xFF3B82F6);
    case DefectSeverity.medium:
      return const Color(0xFFF59E0B);
    case DefectSeverity.high:
      return const Color(0xFFF97316);
    case DefectSeverity.critical:
      return const Color(0xFFEF4444);
  }
}

String defectSeverityLabel(DefectSeverity severity) {
  return severity.name[0].toUpperCase() + severity.name.substring(1);
}

class DefectSeverityChip extends StatelessWidget {
  final DefectSeverity severity;

  const DefectSeverityChip({super.key, required this.severity});

  @override
  Widget build(BuildContext context) {
    final color = defectSeverityColor(severity);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        defectSeverityLabel(severity),
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class DefectStatusChip extends StatelessWidget {
  final String status;

  const DefectStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final isResolved = status == DefectStatus.resolved;
    final color = isResolved ? const Color(0xFF22C55E) : const Color(0xFFF59E0B);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }
}
