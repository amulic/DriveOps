import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driveops_management/shared/providers/repository_providers.dart';

final userNamesProvider = FutureProvider.family<Map<String, String>, String>((ref, idsKey) async {
  if (idsKey.isEmpty) return {};
  final keycloakIds = idsKey.split(',');
  final driverRepo = ref.watch(driverRepositoryProvider);
  final result = <String, String>{};
  for (final kcId in keycloakIds) {
    try {
      final driver = await driverRepo.getDriverByKeycloakId(kcId);
      if (driver != null) {
        result[kcId] = driver.fullName;
      }
    } catch (_) {
      // ignore — single driver lookup failures shouldn't break the whole batch
    }
  }
  return result;
});
