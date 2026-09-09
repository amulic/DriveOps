import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driveops_management/shared/providers/repository_providers.dart';

final userNamesProvider = FutureProvider.family<Map<String, String>, List<String>>((ref, keycloakIds) async {
  if (keycloakIds.isEmpty) return {};
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
