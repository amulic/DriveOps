import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driveops_mobile/shared/models/user.dart';
import 'package:driveops_mobile/services/auth_service.dart';
import 'package:driveops_mobile/services/cache_service.dart';

class AuthState {
  final User? user;
  final String? error;

  const AuthState({this.user, this.error});

  bool get isAuthenticated => user != null;

  String? get keycloakSub => user?.keycloakId;
}

class AuthNotifier extends AsyncNotifier<AuthState> {
  late final AuthService _authService;

  @override
  Future<AuthState> build() async {
    _authService = AuthService();
    return _checkAuthState();
  }

  Future<AuthState> _checkAuthState() async {
    try {
      final isAuth = await _authService.isAuthenticated();
      if (isAuth) {
        final token = await _authService.getAccessToken();
        if (token != null) {
          final user = await _buildUserFromToken(token);
          if (user != null) {
            return AuthState(user: user);
          }
        }
      }
      return const AuthState();
    } catch (_) {
      return const AuthState();
    }
  }

  Future<void> login() async {
    if (_authService.isLoggingIn) return;
    state = const AsyncValue.loading();
    try {
      final result = await _authService.login();
      if (result.success && result.tokens != null) {
        final user = await _buildUserFromToken(result.tokens!.accessToken);
        state = AsyncValue.data(AuthState(user: user));
      } else {
        state = AsyncValue.data(AuthState(error: result.error ?? 'Login failed'));
      }
    } catch (e) {
      state = AsyncValue.data(AuthState(error: e.toString()));
    }
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    try {
      await _authService.logout();
    } catch (_) {}
    await CacheService().clear();
    state = const AsyncValue.data(AuthState());
  }

  Future<void> reloadUser() async {
    try {
      final tokens = await _authService.refreshToken();
      if (tokens != null) {
        final user = await _buildUserFromToken(tokens.accessToken);
        if (user != null) {
          state = AsyncValue.data(AuthState(user: user));
        }
      }
    } catch (_) {
      // Keep the current state if the reload fails.
    }
  }

  Future<User?> _buildUserFromToken(String token) async {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final data = jsonDecode(payload) as Map<String, dynamic>;

      final sub = data['sub'] as String?;
      final email = data['email'] as String?;
      final givenName = data['given_name'] as String? ?? '';
      final familyName = data['family_name'] as String? ?? '';
      final preferredUsername = data['preferred_username'] as String?;

      final userType = _resolveUserType(data);
      final roles = _extractRoles(data);

      if (sub == null) return null;

      return User(
        id: sub,
        keycloakId: sub,
        email: email ?? '',
        firstName: givenName,
        lastName: familyName,
        userType: userType,
        roles: roles,
        username: preferredUsername,
      );
    } catch (_) {
      return null;
    }
  }

  UserType _resolveUserType(Map<String, dynamic> payload) {
    final roles = _extractRoles(payload);
    if (roles.contains('admin')) return UserType.admin;
    if (roles.contains('dispatcher')) return UserType.dispatcher;
    if (roles.contains('driver')) return UserType.driver;
    if (roles.contains('customer')) return UserType.customer;
    return UserType.customer;
  }

  List<String> _extractRoles(Map<String, dynamic> payload) {
    final roles = <String>{};
    final realmAccess = payload['realm_access'] as Map<String, dynamic>?;
    if (realmAccess != null) {
      final realmRoles = realmAccess['roles'] as List<dynamic>?;
      if (realmRoles != null) {
        for (final r in realmRoles) {
          if (r is String) roles.add(r);
        }
      }
    }
    final resourceAccess = payload['resource_access'] as Map<String, dynamic>?;
    if (resourceAccess != null) {
      for (final entry in resourceAccess.entries) {
        final client = entry.value as Map<String, dynamic>?;
        final clientRoles = client?['roles'] as List<dynamic>?;
        if (clientRoles != null) {
          for (final r in clientRoles) {
            if (r is String) roles.add(r);
          }
        }
      }
    }
    return roles.toList();
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(() => AuthNotifier());

final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authProvider);
  return authState.value?.isAuthenticated ?? false;
});

final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authProvider);
  return authState.value?.user;
});

final keycloakSubProvider = Provider<String?>((ref) {
  final authState = ref.watch(authProvider);
  return authState.value?.keycloakSub;
});

/// The mobile app serves drivers and customers — admins/dispatchers should
/// use the desktop management app instead.
final isMobileRoleProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;
  return user.userType == UserType.driver || user.userType == UserType.customer;
});

final isDriverProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.userType == UserType.driver;
});
