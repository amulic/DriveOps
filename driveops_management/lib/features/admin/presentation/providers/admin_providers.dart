import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driveops_management/services/admin_api_service.dart';
import 'package:driveops_management/shared/models/admin_account.dart';

final adminAccountsProvider =
    FutureProvider.family<List<AdminAccount>, String>((ref, search) async {
  final api = ref.watch(adminApiServiceProvider);
  return api.getAccounts(search: search);
});

final fareSettingsProvider = FutureProvider<FareSettings>((ref) async {
  final api = ref.watch(adminApiServiceProvider);
  return api.getFareSettings();
});
