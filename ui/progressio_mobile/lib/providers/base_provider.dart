import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:progressio_mobile/model/search_result.dart';
import 'package:progressio_mobile/providers/auth_provider.dart';

abstract class BaseProvider<T> with ChangeNotifier {
  static String? _baseUrl;
  String _endpoint = '';

  BaseProvider(String endpoint) {
    _endpoint = endpoint;
    _baseUrl = const String.fromEnvironment(
      'baseUrl',
     defaultValue: 'https://10.0.2.2:7204/api/',
    );
  }

  String get endpoint => _endpoint;


  Future<SearchResult<T>> get({dynamic filter}) async {
    var url = '$_baseUrl$_endpoint';

    if (filter != null) {
      final qs = getQueryString(filter);
      url = '$url?$qs';
    }

    final response = await http.get(Uri.parse(url), headers: createHeaders());

    if (isValidResponse(response)) {
      final data = jsonDecode(response.body);
      final result = SearchResult<T>();
      result.totalCount = data['totalCount'];
      result.items = List<T>.from(data['items'].map((e) => fromJson(e)));
      return result;
    } else {
      throw Exception('Unknown error');
    }
  }


  Future<T> getById(int id) async {
    final url = '$_baseUrl$_endpoint/$id';
    final response = await http.get(Uri.parse(url), headers: createHeaders());

    if (isValidResponse(response)) {
      return fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Unknown error');
    }
  }


  Future<T> insert(dynamic request) async {
    final url = '$_baseUrl$_endpoint';
    final response = await http.post(
      Uri.parse(url),
      headers: createHeaders(),
      body: jsonEncode(request),
    );

    if (isValidResponse(response)) {
      return fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Unknown error');
    }
  }

 
  Future<T> update(int id, dynamic request) async {
    final url = '$_baseUrl$_endpoint/$id';
    final response = await http.put(
      Uri.parse(url),
      headers: createHeaders(),
      body: jsonEncode(request),
    );

    if (isValidResponse(response)) {
      return fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Unknown error');
    }
  }

 
  Future<void> delete(int id) async {
    final url = '$_baseUrl$_endpoint/$id';
    final response = await http.delete(Uri.parse(url), headers: createHeaders());

    if (response.statusCode >= 299 && response.statusCode != 204) {
      if (response.statusCode == 401) throw Exception('Unauthorized');
      throw Exception('Delete failed');
    }
  }

 
  Future<dynamic> getRaw(String path, {Map<String, dynamic>? query}) async {
    var url = '$_baseUrl$path';
    if (query != null) url = '$url?${getQueryString(query)}';
    final response = await http.get(Uri.parse(url), headers: createHeaders());
    if (isValidResponse(response)) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Unknown error');
    }
  }

 
  Future<dynamic> postRaw(String path, dynamic body) async {
    final url = '$_baseUrl$path';
    final response = await http.post(
      Uri.parse(url),
      headers: createHeaders(),
      body: jsonEncode(body),
    );
    if (isValidResponse(response)) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } else {
      throw Exception('Unknown error');
    }
  }

  T fromJson(dynamic data) {
    throw Exception('fromJson not implemented');
  }

  bool isValidResponse(Response response) {
    if (response.statusCode < 299) return true;
    if (response.statusCode == 204) return true;
    if (response.statusCode == 401) throw Exception('Unauthorized');
    debugPrint('API error ${response.statusCode}: ${response.body}');
    throw Exception('Server error: ${response.statusCode}');
  }

  Map<String, String> createHeaders() {
    
    if (AuthProvider.token != null && AuthProvider.token!.isNotEmpty) {
      return {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AuthProvider.token}',
      };
    }

    final username = AuthProvider.username ?? '';
    final password = AuthProvider.password ?? '';
    final basicAuth = 'Basic ${base64Encode(utf8.encode('$username:$password'))}';
    return {
      'Content-Type': 'application/json',
      'Authorization': basicAuth,
    };
  }

  Future<dynamic> deleteRaw(String path) async {
  final url = '$_baseUrl$path';
  final response = await http.delete(Uri.parse(url), headers: createHeaders());
  if (response.statusCode == 204 || response.statusCode < 300) return null;
  if (response.statusCode == 401) throw Exception('Unauthorized');
  throw Exception('Delete failed: ${response.statusCode}');
}

  String getQueryString(Map params,
      {String prefix = '&', bool inRecursion = false}) {
    String query = '';
    params.forEach((key, value) {
      if (inRecursion) {
        key = value is List || value is Map ? '.$key' : '.$key';
      }
      if (value is String || value is int || value is double || value is bool) {
        final encoded = value is String ? Uri.encodeComponent(value) : value;
        query += '$prefix$key=$encoded';
      } else if (value is DateTime) {
        query += '$prefix$key=${value.toIso8601String()}';
      } else if (value is List || value is Map) {
        if (value is List) value = value.asMap();
        value.forEach((k, v) {
          query += getQueryString({k: v},
              prefix: '$prefix$key', inRecursion: true);
        });
      }
    });
    return query;
  }
}