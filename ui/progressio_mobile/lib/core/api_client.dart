import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:http_parser/http_parser.dart';
import 'package:progressio_mobile/core/api_config.dart';
import 'package:progressio_mobile/core/api_exception.dart';
import 'package:progressio_mobile/providers/auth_provider.dart';

class ApiClient {
  static void Function()? onSessionExpired;
  static bool _refreshInProgress = false;

  
 static final http.Client _client = kDebugMode
    ? IOClient(HttpClient()..badCertificateCallback = (cert, host, port) => true)
    : http.Client();


  static Future<http.Response> get(
    String path, {
    Map<String, dynamic>? query,
    bool requiresAuth = true,
  }) =>
      _request('GET', path, query: query, requiresAuth: requiresAuth);

  static Future<http.Response> post(
    String path, {
    Object? body,
    bool requiresAuth = true,
  }) =>
      _request('POST', path, body: body, requiresAuth: requiresAuth);

  static Future<http.Response> put(
    String path, {
    Object? body,
    bool requiresAuth = true,
  }) =>
      _request('PUT', path, body: body, requiresAuth: requiresAuth);

  static Future<http.Response> delete(
    String path, {
    bool requiresAuth = true,
  }) =>
      _request('DELETE', path, requiresAuth: requiresAuth);

  static Future<http.Response> uploadFile(
    String path, {
    required String fieldName,
    required String filePath,
    Map<String, String>? fields,
    bool requiresAuth = true,
    bool retryAfterRefresh = true,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse(ApiConfig.resolve(path)));
    if (requiresAuth && AuthProvider.token?.isNotEmpty == true) {
      request.headers['Authorization'] = 'Bearer ${AuthProvider.token}';
    }
    if (fields != null) request.fields.addAll(fields);

    request.files.add(
      await http.MultipartFile.fromPath(
        fieldName,
        filePath,
        contentType: _mediaTypeForFile(filePath),
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 401 &&
        requiresAuth &&
        retryAfterRefresh &&
        await _refreshAccessToken()) {
      return uploadFile(
        path,
        fieldName: fieldName,
        filePath: filePath,
        fields: fields,
        requiresAuth: requiresAuth,
        retryAfterRefresh: false,
      );
    }

    _throwForError(response, requiresAuth: requiresAuth);
    return response;
  }

  static Future<http.Response> _request(
    String method,
    String path, {
    Map<String, dynamic>? query,
    Object? body,
    required bool requiresAuth,
    bool retryAfterRefresh = true,
  }) async {
    final uri = Uri.parse(ApiConfig.resolve(path)).replace(
      queryParameters: query?.map(
        (key, value) => MapEntry(key, value?.toString()),
      ),
    );

    final headers = <String, String>{'Content-Type': 'application/json'};
    if (requiresAuth && AuthProvider.token?.isNotEmpty == true) {
      headers['Authorization'] = 'Bearer ${AuthProvider.token}';
    }

    late http.Response response;
    final encodedBody = body == null ? null : jsonEncode(body);

    if (kDebugMode) {
      debugPrint('[ApiClient] -> $method $uri');
      if (encodedBody != null) {
        debugPrint('[ApiClient] body: ${_redactBody(encodedBody)}');
      }
    }

    switch (method) {
      case 'GET':
        response = await http.get(uri, headers: headers);
        break;
      case 'POST':
        response = await http.post(uri, headers: headers, body: encodedBody);
        break;
      case 'PUT':
        response = await http.put(uri, headers: headers, body: encodedBody);
        break;
      case 'DELETE':
        response = await http.delete(uri, headers: headers);
        break;
      default:
        throw const ApiException('Unsupported HTTP method.');
    }

    if (kDebugMode) {
      debugPrint('[ApiClient] <- ${response.statusCode} $uri');
      debugPrint('[ApiClient] response body: ${_redactBody(response.body)}');
    }

    if (response.statusCode == 401 &&
        requiresAuth &&
        retryAfterRefresh &&
        await _refreshAccessToken()) {
      if (kDebugMode) debugPrint('[ApiClient] 401 -> retrying after token refresh');
      return _request(
        method,
        path,
        query: query,
        body: body,
        requiresAuth: requiresAuth,
        retryAfterRefresh: false,
      );
    }

    _throwForError(response, requiresAuth: requiresAuth);
    return response;
  }

  static void _throwForError(
    http.Response response, {
    required bool requiresAuth,
  }) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;

    if (kDebugMode) {
      debugPrint('[ApiClient] _throwForError statusCode=${response.statusCode}');
    }

    if (response.statusCode == 401 && requiresAuth) {
      if (kDebugMode) debugPrint('[ApiClient] 401 -> clearing auth + onSessionExpired');
      AuthProvider.clear();
      onSessionExpired?.call();
    }

    final msg = _extractErrorMessage(response);
    if (kDebugMode) {
      debugPrint('[ApiClient] throwing ApiException: $msg (status ${response.statusCode})');
    }

    throw ApiException(
      msg,
      statusCode: response.statusCode,
    );
  }

  static MediaType _mediaTypeForFile(String filePath) {
    final normalized = filePath.toLowerCase();
    if (normalized.endsWith('.png')) return MediaType('image', 'png');
    if (normalized.endsWith('.webp')) return MediaType('image', 'webp');
    if (normalized.endsWith('.jpg') || normalized.endsWith('.jpeg')) {
      return MediaType('image', 'jpeg');
    }
    throw const ApiException('Only JPG, PNG and WebP images are allowed.');
  }

  static Future<bool> _refreshAccessToken() async {
    if (_refreshInProgress) {
      while (_refreshInProgress) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      return AuthProvider.isLoggedIn;
    }

    final refreshToken = AuthProvider.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) return false;

    _refreshInProgress = true;
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.resolve('auth/refresh')),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        AuthProvider.clear();
        return false;
      }

      AuthProvider.applyLoginResponse(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
      return true;
    } catch (_) {
      AuthProvider.clear();
      return false;
    } finally {
      _refreshInProgress = false;
    }
  }

  static dynamic decode(http.Response response) {
    if (response.body.trim().isEmpty) return null;
    return jsonDecode(response.body);
  }

  // Redaktuje osjetljiva polja iz JSON body-ja prije logovanja.
  // Pokriva request body (lozinke, tokeni) i response body (access/refresh tokeni, Stripe secret).
  static String _redactBody(String body) {
    const sensitiveKeys = [
      'password',
      'currentPassword',
      'newPassword',
      'token',
      'accessToken',
      'refreshToken',
      'clientSecret',
      'client_secret',
      'resetToken',
    ];

    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final redacted = Map<String, dynamic>.from(decoded);
        for (final key in sensitiveKeys) {
          if (redacted.containsKey(key)) {
            redacted[key] = '[REDACTED]';
          }
        }
        return jsonEncode(redacted);
      }
    } catch (_) {
      // Not valid JSON - return body as-is
    }
    return body;
  }

  static String _extractErrorMessage(http.Response response) {
    final fallback = 'Request failed with status ${response.statusCode}.';
    try {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) {
        final direct = data['detail'] ?? data['message'] ?? data['title'];
        if (direct is String && direct.trim().isNotEmpty) return direct;

        final errors = data['errors'];
        if (errors is Map) {
          final messages = errors.values
              .expand((value) => value is List ? value : [value])
              .map((value) => value.toString())
              .where((value) => value.trim().isNotEmpty)
              .toList();
          if (messages.isNotEmpty) return messages.join('\n');
        }
      }
      return fallback;
    } on FormatException {
      return fallback;
    }
  }
}