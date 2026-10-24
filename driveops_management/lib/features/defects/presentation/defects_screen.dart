import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driveops_management/shared/models/defect_report.dart';
import 'package:driveops_management/features/defects/presentation/providers/defects_providers.dart';
import 'package:driveops_management/features/defects/presentation/widgets/defect_chips.dart';
import 'package:driveops_management/features/defects/presentation/widgets/defect_detail_dialog.dart';

class DefectsScreen extends ConsumerWidget {
  const DefectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final defectsAsync = ref.watch(defectsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, ref, defectsAsync),
          _buildFilters(ref),
          const SizedBox(height: 8),
          Expanded(
            child: defectsAsync.when(
              data: (defects) => defects.isEmpty
                  ? _buildEmpty(ref)
                  : _buildList(context, defects),
              loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
              ),
              error: (error, _) => _buildError(ref, error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, AsyncValue<List<DefectReport>> defectsAsync) {
    final count = defectsAsync.value?.length ?? 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Row(
        children: [
          const Text(
            'Defect Reports',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: const TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.w600),
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {
              ref.invalidate(defectsProvider);
              ref.invalidate(openDefectCountsProvider);
            },
            icon: const Icon(Icons.refresh, color: Colors.white54),
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(WidgetRef ref) {
    final statusFilter = ref.watch(defectStatusFilterProvider);
    final severityFilter = ref.watch(defectSeverityFilterProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        children: [
          _statusChip(ref, label: 'All', value: null, selected: statusFilter == null),
          const SizedBox(width: 8),
          _statusChip(ref, label: 'Open', value: DefectStatus.reported, selected: statusFilter == DefectStatus.reported),
          const SizedBox(width: 8),
          _statusChip(ref, label: 'Resolved', value: DefectStatus.resolved, selected: statusFilter == DefectStatus.resolved),
          const SizedBox(width: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF252538),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<DefectSeverity?>(
                value: severityFilter,
                dropdownColor: const Color(0xFF252538),
                style: const TextStyle(color: Colors.white, fontSize: 13),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white54),
                items: [
                  const DropdownMenuItem<DefectSeverity?>(
                    value: null,
                    child: Text('All severities'),
                  ),
                  ...DefectSeverity.values.map((s) => DropdownMenuItem<DefectSeverity?>(
                        value: s,
                        child: Text(defectSeverityLabel(s)),
                      )),
                ],
                onChanged: (value) {
                  ref.read(defectSeverityFilterProvider.notifier).update(value);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(WidgetRef ref, {required String label, required String? value, required bool selected}) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        ref.read(defectStatusFilterProvider.notifier).update(value);
      },
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.white54,
        fontSize: 13,
      ),
      backgroundColor: const Color(0xFF252538),
      selectedColor: const Color(0xFF3B82F6).withValues(alpha: 0.3),
      checkmarkColor: Colors.white,
      side: BorderSide(
        color: selected ? const Color(0xFF3B82F6) : Colors.white12,
      ),
    );
  }

  Widget _buildList(BuildContext context, List<DefectReport> defects) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      itemCount: defects.length,
      itemBuilder: (context, index) => _DefectCard(defect: defects[index]),
    );
  }

  Widget _buildEmpty(WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.build_circle_outlined, color: Colors.white24, size: 56),
          const SizedBox(height: 12),
          const Text(
            'No defect reports match the filters',
            style: TextStyle(color: Colors.white38, fontSize: 15),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => ref.invalidate(defectsProvider),
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildError(WidgetRef ref, Object error) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 48),
          const SizedBox(height: 16),
          Text('Failed to load defect reports: $error', style: const TextStyle(color: Colors.white54)),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => ref.invalidate(defectsProvider),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _DefectCard extends ConsumerWidget {
  final DefectReport defect;

  const _DefectCard({required this.defect});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      color: const Color(0xFF252538),
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => showDialog(
          context: context,
          builder: (context) => DefectDetailDialog(defect: defect),
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: defectSeverityColor(defect.severity).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.build_outlined,
                  color: defectSeverityColor(defect.severity),
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      defect.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${defect.vehicleLabel}  ·  reported by ${defect.driverName ?? 'unknown'}',
                      style: const TextStyle(color: Colors.white54, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDateTime(defect.reportedAt),
                      style: const TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              DefectSeverityChip(severity: defect.severity),
              const SizedBox(width: 8),
              DefectStatusChip(status: defect.status),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: Colors.white38),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${date.month}/${date.day}/${date.year} ${two(date.hour)}:${two(date.minute)}';
  }
}
