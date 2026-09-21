import 'dart:convert';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:driveops_mobile/config/api_config.dart';

class AuthTokens {
  final String accessToken;
  final String refreshToken;
  final String idToken;
  final DateTime expiresAt;

  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.idToken,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

class AuthResult {
  final bool success;
  final AuthTokens? tokens;
  final String? error;

  const AuthResult({required this.success, this.tokens, this.error});

  factory AuthResult.success(AuthTokens tokens) => AuthResult(success: true, tokens: tokens);
  factory AuthResult.failure(String error) => AuthResult(success: false, error: error);
}

/// Keycloak PKCE auth for the mobile app via flutter_appauth
/// (native Chrome Custom Tabs on Android).
class AuthService {
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _idTokenKey = 'id_token';
  static const _expiresAtKey = 'expires_at';
  static const _keycloakSubKey = 'keycloak_sub';

  final FlutterSecureStorage _secureStorage;
  final FlutterAppAuth _appAuth;

  bool _isLoggingIn = false;

  AuthService()
      : _secureStorage = const FlutterSecureStorage(
          aOptions: AndroidOptions(),
        ),
        _appAuth = const FlutterAppAuth();

  bool get isLoggingIn => _isLoggingIn;

  Future<AuthResult> login() async {
    if (_isLoggingIn) {
      return const AuthResult(success: false, error: 'Login already in progress');
    }
    _isLoggingIn = true;

    try {
      final result = await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          KeycloakConfig.clientId,
          KeycloakConfig.redirectUri,
          issuer: KeycloakConfig.authority,
          scopes: KeycloakConfig.scopes.split(' '),
          // Dev Keycloak runs on plain HTTP.
          allowInsecureConnections: true,
        ),
      );

      if (result.accessToken == null) {
        return const AuthResult(success: false, error: 'Login cancelled');
      }

      final tokens = AuthTokens(
        accessToken: result.accessToken!,
        refreshToken: result.refreshToken ?? '',
        idToken: result.idToken ?? '',
        expiresAt: result.accessTokenExpirationDateTime ??
            DateTime.now().add(const Duration(minutes: 15)),
      );

      await _storeTokens(tokens);
      return AuthResult.success(tokens);
    } catch (e) {
      return AuthResult.failure('Login failed: $e');
    } finally {
      _isLoggingIn = false;
    }
  }

  Future<void> _storeTokens(AuthTokens tokens) async {
    await _secureStorage.write(key: _accessTokenKey, value: tokens.accessToken);
    await _secureStorage.write(key: _refreshTokenKey, value: tokens.refreshToken);
    await _secureStorage.write(key: _idTokenKey, value: tokens.idToken);
    await _secureStorage.write(key: _expiresAtKey, value: tokens.expiresAt.toIso8601String());
  }

  Future<AuthTokens?> refreshToken() async {
    try {
      final refreshToken = await _secureStorage.read(key: _refreshTokenKey);
      if (refreshToken == null || refreshToken.isEmpty) return null;

      final result = await _appAuth.token(
        TokenRequest(
          KeycloakConfig.clientId,
          KeycloakConfig.redirectUri,
          issuer: KeycloakConfig.authority,
          refreshToken: refreshToken,
          grantType: GrantType.refreshToken,
          allowInsecureConnections: true,
        ),
      );

      if (result.accessToken == null) {
        await clearTokens();
        return null;
      }

      final tokens = AuthTokens(
        accessToken: result.accessToken!,
        refreshToken: result.refreshToken ?? refreshToken,
        idToken: result.idToken ?? '',
        expiresAt: result.accessTokenExpirationDateTime ??
            DateTime.now().add(const Duration(minutes: 15)),
      );

      await _storeTokens(tokens);
      return tokens;
    } catch (_) {
      await clearTokens();
      return null;
    }
  }

  Future<String?> getAccessToken() async {
    final expiresAtStr = await _secureStorage.read(key: _expiresAtKey);
    if (expiresAtStr == null) return null;

    final expiresAt = DateTime.tryParse(expiresAtStr);
    if (expiresAt == null) return null;

    if (DateTime.now().isAfter(expiresAt.subtract(const Duration(minutes: 1)))) {
      final tokens = await refreshToken();
      return tokens?.accessToken;
    }

    return _secureStorage.read(key: _accessTokenKey);
  }

  Future<String?> getKeycloakSub() async {
    final cached = await _secureStorage.read(key: _keycloakSubKey);
    if (cached != null) return cached;

    final token = await getAccessToken();
    if (token == null) return null;

    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final sub = data['sub'] as String?;
      if (sub != null) {
        await _secureStorage.write(key: _keycloakSubKey, value: sub);
      }
      return sub;
    } catch (_) {
      return null;
    }
  }

  Future<void> logout() async {
    final idToken = await _secureStorage.read(key: _idTokenKey);
    await clearTokens();

    if (idToken == null || idToken.isEmpty) return;

    try {
      await _appAuth.endSession(
        EndSessionRequest(
          idTokenHint: idToken,
          postLogoutRedirectUrl: KeycloakConfig.postLogoutRedirectUri,
          issuer: KeycloakConfig.authority,
          allowInsecureConnections: true,
        ),
      );
    } catch (_) {
      // Local tokens are already cleared; a failed remote logout is non-fatal.
    }
  }

  Future<void> clearTokens() async {
    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
    await _secureStorage.delete(key: _idTokenKey);
    await _secureStorage.delete(key: _expiresAtKey);
    await _secureStorage.delete(key: _keycloakSubKey);
  }

  Future<bool> isAuthenticated() async {
    final token = await _secureStorage.read(key: _accessTokenKey);
    return token != null;
  }
}
