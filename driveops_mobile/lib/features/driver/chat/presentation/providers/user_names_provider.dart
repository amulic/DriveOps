import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driveops_mobile/shared/providers/repository_providers.dart';

/// Resolves display names for chat participants (Keycloak subs) by probing
/// the driver repository first, then the customer repository — drivers chat
/// with customers, so both lookups are needed.
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
    } catch (_) {
      // ignore — single lookup failures shouldn't break the whole batch
    }
  }
  return result;
});
