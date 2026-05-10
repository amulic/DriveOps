import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/api_config.dart';

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

class AuthService {
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _idTokenKey = 'id_token';
  static const _expiresAtKey = 'expires_at';
  static const _stateKey = 'oauth_state';

  final FlutterSecureStorage _secureStorage;

  String? _codeVerifier;
  HttpServer? _redirectServer;

  AuthService() : _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  String _generateCodeVerifier() {
    final random = Random.secure();
    final values = List<int>.generate(128, (_) => random.nextInt(256));
    return base64Url.encode(values).replaceAll('=', '');
  }

  String _generateCodeChallenge(String codeVerifier) {
    final bytes = utf8.encode(codeVerifier);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  String _generateState() {
    final random = Random.secure();
    final values = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Url.encode(values).replaceAll('=', '');
  }

  Future<AuthResult> login() async {
    try {
      final state = _generateState();
      _codeVerifier = _generateCodeVerifier();
      final codeChallenge = _generateCodeChallenge(_codeVerifier!);

      final authUri = Uri.parse(KeycloakConfig.authUrl).replace(
        queryParameters: {
          'response_type': 'code',
          'client_id': KeycloakConfig.clientId,
          'redirect_uri': KeycloakConfig.redirectUri,
          'scope': KeycloakConfig.scopes,
          'state': state,
          'code_challenge': codeChallenge,
          'code_challenge_method': 'S256',
        },
      );

      await _secureStorage.write(key: _stateKey, value: state);

      _redirectServer = await HttpServer.bind(InternetAddress.loopbackIPv4, KeycloakConfig.redirectPort);

      final completer = Completer<AuthResult>();

      _redirectServer!.listen(
        (request) async {
          if (request.uri.path == '/auth/callback') {
            final params = request.uri.queryParameters;
            final returnedState = params['state'] ?? '';
            final code = params['code'];
            final error = params['error'];

            if (error != null) {
              request.response.write('Authentication failed: $error. Close this window.');
              await request.response.close();
              completer.complete(AuthResult.failure('Authentication failed: $error'));
              return;
            }

            if (returnedState != state) {
              request.response.write('State mismatch. Close this window.');
              await request.response.close();
              completer.complete(AuthResult.failure('State mismatch'));
              return;
            }

            if (code == null) {
              request.response.write('No authorization code received. Close this window.');
              await request.response.close();
              completer.complete(AuthResult.failure('No authorization code'));
              return;
            }

            request.response.write('Authentication successful! You can close this window.');
            await request.response.close();

            try {
              final tokens = await _exchangeCodeForTokens(code);
              await _storeTokens(tokens);
              completer.complete(AuthResult.success(tokens));
            } catch (e) {
              completer.complete(AuthResult.failure('Token exchange failed: $e'));
            }
          } else {
            request.response.statusCode = 404;
            request.response.write('Not found');
            await request.response.close();
          }
        },
        onError: (error) {
          if (!completer.isCompleted) {
            completer.complete(AuthResult.failure('Server error: $error'));
          }
        },
      );

      await launchUrl(authUri, mode: LaunchMode.externalApplication);

      return completer.future.timeout(
        const Duration(minutes: 5),
        onTimeout: () => AuthResult.failure('Authentication timed out'),
      );
    } catch (e) {
      return AuthResult.failure('Login failed: $e');
    } finally {
      await _closeRedirectServer();
      await _secureStorage.delete(key: _stateKey);
      _codeVerifier = null;
    }
  }

  Future<AuthTokens> _exchangeCodeForTokens(String code) async {
    final response = await HttpClient().postUrl(
      Uri.parse(KeycloakConfig.tokenUrl),
    ).then((request) {
      request.headers.contentType = ContentType('application', 'x-www-form-urlencoded');
      request.write(
        'grant_type=authorization_code'
        '&code=$code'
        '&redirect_uri=${Uri.encodeComponent(KeycloakConfig.redirectUri)}'
        '&code_verifier=$_codeVerifier'
        '&client_id=${KeycloakConfig.clientId}',
      );
      return request.close();
    });

    final body = await response.transform(utf8.decoder).join();
    if (response.statusCode != 200) {
      throw Exception('Token exchange failed: $body');
    }

    final data = jsonDecode(body) as Map<String, dynamic>;
    final expiresIn = data['expires_in'] as int;
    final expiresAt = DateTime.now().add(Duration(seconds: expiresIn));

    return AuthTokens(
      accessToken: data['access_token'] as String,
      refreshToken: data['refresh_token'] as String,
      idToken: data['id_token'] as String,
      expiresAt: expiresAt,
    );
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
      if (refreshToken == null) return null;

      final request = await HttpClient().postUrl(Uri.parse(KeycloakConfig.tokenUrl));
      request.headers.contentType = ContentType('application', 'x-www-form-urlencoded');
      request.write(
        'grant_type=refresh_token'
        '&refresh_token=$refreshToken'
        '&client_id=${KeycloakConfig.clientId}',
      );

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode != 200) {
        await clearTokens();
        return null;
      }

      final data = jsonDecode(body) as Map<String, dynamic>;
      final expiresIn = data['expires_in'] as int;
      final expiresAt = DateTime.now().add(Duration(seconds: expiresIn));

      final tokens = AuthTokens(
        accessToken: data['access_token'] as String,
        refreshToken: data['refresh_token'] as String? ?? refreshToken,
        idToken: data['id_token'] as String? ?? '',
        expiresAt: expiresAt,
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

  Future<void> logout() async {
    final idToken = await _secureStorage.read(key: _idTokenKey);
    await clearTokens();

    final logoutUri = Uri.parse(KeycloakConfig.endSessionUrl).replace(
      queryParameters: {
        if (idToken != null) 'id_token_hint': idToken,
        'post_logout_redirect_uri': KeycloakConfig.postLogoutRedirectUri,
      },
    );

    await launchUrl(logoutUri, mode: LaunchMode.externalApplication);
  }

  Future<void> clearTokens() async {
    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
    await _secureStorage.delete(key: _idTokenKey);
    await _secureStorage.delete(key: _expiresAtKey);
  }

  Future<bool> isAuthenticated() async {
    final token = await _secureStorage.read(key: _accessTokenKey);
    return token != null;
  }

  Future<void> _closeRedirectServer() async {
    if (_redirectServer != null) {
      await _redirectServer!.close(force: true);
      _redirectServer = null;
    }
  }
}