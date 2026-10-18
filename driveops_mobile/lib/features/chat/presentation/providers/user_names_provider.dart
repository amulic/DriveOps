import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driveops_mobile/shared/providers/repository_providers.dart';

final userNamesProvider = FutureProvider.family<Map<String, String>, String>((ref, idsKey) async {
  if (idsKey.isEmpty) return {};
  final keycloakIds = idsKey.split(',');
  final driverRepo = ref.watch(driverRepositoryProvider);
  final customerRepo = ref.watch(customerRepositoryProvider);
  final result = <String, String>{};
  for (final kcId in keycloakIds) {
    try {
      final driver = await driverRepo.getDriverByKeycloakId(kcId);
      if (driver != null) {
        result[kcId] = driver.fullName;
        continue;
      }
      final customer = await customerRepo.getCustomerByKeycloakId(kcId);
      if (customer != null) {
        result[kcId] = customer.name;
      }
    } catch (_) {}
  }
  return result;
});
