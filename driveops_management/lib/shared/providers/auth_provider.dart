import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driveops_management/shared/models/user.dart';
import 'package:driveops_management/services/auth_service.dart';
import 'package:driveops_management/services/cache_service.dart';

class AuthState {
  final bool isAuthenticated;
  final User? user;
  final String? keycloakSub;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.isAuthenticated = false,
    this.user,
    this.keycloakSub,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    User? user,
    String? keycloakSub,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      keycloakSub: keycloakSub ?? this.keycloakSub,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
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
          final sub = await _authService.getKeycloakSub();
          return AuthState(isAuthenticated: true, keycloakSub: sub);
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
        final sub = await _authService.getKeycloakSub();
        final user = await _syncUser();
        state = AsyncValue.data(AuthState(isAuthenticated: true, user: user, keycloakSub: sub));
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

  Future<void> register() async {
    if (_authService.isLoggingIn) return;
    state = const AsyncValue.loading();
    try {
      final result = await _authService.register();
      if (result.success && result.tokens != null) {
        final sub = await _authService.getKeycloakSub();
        final user = await _syncUser();
        state = AsyncValue.data(AuthState(isAuthenticated: true, user: user, keycloakSub: sub));
      } else {
        state = AsyncValue.data(AuthState(error: result.error ?? 'Registration failed'));
      }
    } catch (e) {
      state = AsyncValue.data(AuthState(error: e.toString()));
    }
  }

  Future<User?> _syncUser() async {
    try {
      final token = await _authService.getAccessToken();
      if (token == null) return null;

      final syncResponse = await _makeRequest('POST', '/api/user/sync', token);
      if (syncResponse == null) return null;

      final userResponse = await _makeRequest('GET', '/api/user/me', token);
      if (userResponse == null) return null;

      return User.fromJson(userResponse);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _makeRequest(String method, String path, String token) async {
    final uri = Uri.parse('http://localhost:5032$path');
    HttpClientRequest request;
    if (method == 'GET') {
      request = await HttpClient().getUrl(uri);
    } else {
      request = await HttpClient().postUrl(uri);
      request.headers.contentType = ContentType.json;
    }
    request.headers.set('Authorization', 'Bearer $token');

    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(body) as Map<String, dynamic>;
    }
    return null;
  }

  Future<String?> getAccessToken() => _authService.getAccessToken();
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