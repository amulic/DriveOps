import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driveops_management/services/keycloak_account_service.dart';

/// Fetches the current user's profile fresh from the Keycloak Account API.
final accountProfileProvider = FutureProvider<KeycloakAccountProfile>((ref) async {
  final service = ref.watch(keycloakAccountServiceProvider);
  return service.getProfile();
});
