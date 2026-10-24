import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driveops_management/shared/models/defect_report.dart';
import 'package:driveops_management/shared/providers/repository_providers.dart';

class DefectStatusFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null; // null = all

  void update(String? value) => state = value;
}

class DefectSeverityFilterNotifier extends Notifier<DefectSeverity?> {
  @override
  DefectSeverity? build() => null; // null = all

  void update(DefectSeverity? value) => state = value;
}

final defectStatusFilterProvider =
    NotifierProvider<DefectStatusFilterNotifier, String?>(DefectStatusFilterNotifier.new);
final defectSeverityFilterProvider =
    NotifierProvider<DefectSeverityFilterNotifier, DefectSeverity?>(DefectSeverityFilterNotifier.new);

/// Fleet-wide defect list honoring the screen's filters. autoDispose so it
/// refetches on every screen entry (workflow data changes out-of-band too).
final defectsProvider = FutureProvider.autoDispose<List<DefectReport>>((ref) async {
  final repo = ref.watch(defectRepositoryProvider);
  final status = ref.watch(defectStatusFilterProvider);
  final severity = ref.watch(defectSeverityFilterProvider);
  return repo.getDefects(status: status, severity: severity);
});

/// Defects for a single vehicle (vehicle detail dialog, driver vehicle tab).
final vehicleDefectsProvider =
    FutureProvider.autoDispose.family<List<DefectReport>, String>((ref, vehicleId) async {
  final repo = ref.watch(defectRepositoryProvider);
  return repo.getVehicleDefects(vehicleId);
});

/// Open-defect counts keyed by vehicleId — feeds the Vehicles table badge and
/// the sidebar badge.
final openDefectCountsProvider = FutureProvider.autoDispose<Map<String, int>>((ref) async {
  final repo = ref.watch(defectRepositoryProvider);
  final open = await repo.getDefects(status: DefectStatus.reported);
  final counts = <String, int>{};
  for (final d in open) {
    counts[d.vehicleId] = (counts[d.vehicleId] ?? 0) + 1;
  }
  return counts;
});

final totalOpenDefectsProvider = Provider.autoDispose<int>((ref) {
  final counts = ref.watch(openDefectCountsProvider);
  return counts.maybeWhen(
    data: (map) => map.values.fold<int>(0, (sum, c) => sum + c),
    orElse: () => 0,
  );
});

/// Mutations — every action invalidates the interdependent defect providers so
/// the Defects screen, vehicle dialog section and Vehicles table badges stay
/// in sync without manual refreshes.
final defectActionsProvider = Provider<DefectActions>((ref) => DefectActions(ref));

class DefectActions {
  final Ref _ref;

  DefectActions(this._ref);

  Future<void> resolve(String defectId, String? resolutionNotes) async {
    await _ref.read(defectRepositoryProvider).resolveDefect(defectId, resolutionNotes: resolutionNotes);
    _invalidateAll();
  }

  Future<void> reopen(String defectId) async {
    await _ref.read(defectRepositoryProvider).reopenDefect(defectId);
    _invalidateAll();
  }

  void _invalidateAll() {
    _ref.invalidate(defectsProvider);
    _ref.invalidate(vehicleDefectsProvider);
    _ref.invalidate(openDefectCountsProvider);
  }
}
