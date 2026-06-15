import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:progressio_desktop/core/api_config.dart';
import 'package:progressio_desktop/core/api_exception.dart';
import 'package:progressio_desktop/providers/auth_provider.dart';

class ApiClient {
  static bool _refreshInProgress = false;

  // Timeout za svaki HTTP zahtjev
  static const Duration _timeout = Duration(seconds: 20);

  static Future<http.Response> get(String path, {Map<String, dynamic>? query}) =>
      _request('GET', path, query: query);

  static Future<http.Response> post(
    String path, {
    Object? body,
    bool requiresAuth = true,
  }) =>
      _request('POST', path, body: body, requiresAuth: requiresAuth);

  static Future<http.Response> put(String path, {Object? body}) =>
      _request('PUT', path, body: body);

  static Future<http.Response> delete(String path) => _request('DELETE', path);

  static Future<http.Response> _request(
    String method,
    String path, {
    Map<String, dynamic>? query,
    Object? body,
    bool requiresAuth = true,
    bool retryAfterRefresh = true,
  }) async {
    final uri = Uri.parse(ApiConfig.resolve(path)).replace(
      queryParameters: query?.map((key, value) => MapEntry(key, value?.toString())),
    );
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (requiresAuth && AuthProvider.token?.isNotEmpty == true) {
      headers['Authorization'] = 'Bearer ${AuthProvider.token}';
    }

    final encoded = body == null ? null : jsonEncode(body);

    try {
      late http.Response response;
      switch (method) {
        case 'GET':
          response = await http.get(uri, headers: headers).timeout(_timeout);
          break;
        case 'POST':
          response = await http.post(uri, headers: headers, body: encoded).timeout(_timeout);
          break;
        case 'PUT':
          response = await http.put(uri, headers: headers, body: encoded).timeout(_timeout);
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: headers).timeout(_timeout);
          break;
        default:
          throw const ApiException('Unsupported HTTP method.');
      }

      if (response.statusCode == 401 && requiresAuth && retryAfterRefresh && await _refresh()) {
        return _request(
          method,
          path,
          query: query,
          body: body,
          requiresAuth: requiresAuth,
          retryAfterRefresh: false,
        );
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(_message(response), statusCode: response.statusCode);
      }

      return response;
    } on ApiException {
      rethrow;
    } on SocketException {
      throw const ApiException(
        'Nije moguće povezati se sa serverom. Provjerite internet konekciju.',
      );
    } on TimeoutException {
      throw const ApiException(
        'Server ne odgovara. Pokušajte ponovo.',
      );
    } on FormatException {
      throw const ApiException(
        'Server je vratio neispravan odgovor. Pokušajte ponovo.',
      );
    } catch (e) {
      throw ApiException('Neočekivana greška: $e');
    }
  }

  static Future<bool> _refresh() async {
    if (_refreshInProgress) {
      while (_refreshInProgress) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      return AuthProvider.token?.isNotEmpty == true;
    }

    final refreshToken = AuthProvider.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) return false;

    _refreshInProgress = true;
    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.resolve('auth/refresh')),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'refreshToken': refreshToken}),
          )
          .timeout(_timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        AuthProvider.clear();
        return false;
      }
      AuthProvider.applyLoginResponse(jsonDecode(response.body) as Map<String, dynamic>);
      return AuthProvider.isAdmin;
    } on Exception {
      AuthProvider.clear();
      return false;
    } finally {
      _refreshInProgress = false;
    }
  }

  static dynamic decode(http.Response response) {
    if (response.body.trim().isEmpty) return null;
    try {
      return jsonDecode(response.body);
    } on FormatException {
      throw const ApiException('Server je vratio neispravan format podataka.');
    }
  }

  static String _message(http.Response response) {
    final code = response.statusCode;
    final fallback = _fallbackMessage(code);
    try {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) {
        // Pokušaj izvući poruku iz poznatih polja
        final value = data['detail'] ?? data['message'] ?? data['title'] ?? data['error'];
        if (value is String && value.isNotEmpty) return value;

        // Podrška za ASP.NET ValidationProblem errors objekat
        final errors = data['errors'];
        if (errors is Map<String, dynamic>) {
          final msgs = errors.values
              .expand((v) => v is List ? v.map((e) => e.toString()) : [v.toString()])
              .where((s) => s.isNotEmpty)
              .toList();
          if (msgs.isNotEmpty) return msgs.join(', ');
        }
      }
      return fallback;
    } on FormatException {
      return fallback;
    }
  }

  static String _fallbackMessage(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Zahtjev nije ispravan. Provjerite unesene podatke.';
      case 401:
        return 'Niste prijavljeni ili je sesija istekla. Prijavite se ponovo.';
      case 403:
        return 'Nemate dozvolu za ovu akciju.';
      case 404:
        return 'Traženi resurs nije pronađen.';
      case 409:
        return 'Konflikt: zapis već postoji ili je u upotrebi.';
      case 422:
        return 'Podaci nisu prošli validaciju. Provjerite unos.';
      case 500:
        return 'Greška na serveru. Pokušajte ponovo.';
      case 503:
        return 'Server trenutno nije dostupan. Pokušajte ponovo.';
      default:
        return 'Zahtjev nije uspio (status $statusCode).';
    }
  }
}