import 'package:flutter/material.dart';
import 'package:progressio_mobile/core/api_client.dart';
import 'package:progressio_mobile/model/search_result.dart';

abstract class BaseProvider<T> with ChangeNotifier {
  final String endpoint;

  BaseProvider(this.endpoint);

  Future<SearchResult<T>> get({dynamic filter}) async {
    final query = filter is Map<String, dynamic> ? filter : null;
    final response = await ApiClient.get(endpoint, query: query);
    final data = ApiClient.decode(response) as Map<String, dynamic>;

    return SearchResult<T>()
      ..totalCount = data['totalCount'] as int? ?? 0
      ..items = (data['items'] as List<dynamic>? ?? const [])
          .map(fromJson)
          .toList();
  }

  Future<List<T>> getAll({
    Map<String, dynamic>? filter,
    int pageSize = 100,
  }) async {
    final safePageSize = pageSize < 1 ? 1 : (pageSize > 100 ? 100 : pageSize);
    final items = <T>[];
    var page = 1;

    while (true) {
      final result = await get(
        filter: {
          ...?filter,
          'page': page,
          'pageSize': safePageSize,
        },
      );
      final pageItems = result.items;
      items.addAll(pageItems);

      final totalCount = result.totalCount ?? items.length;
      if (pageItems.isEmpty || items.length >= totalCount) break;
      page++;
    }

    return items;
  }

  Future<T> getById(int id) async {
    final response = await ApiClient.get('$endpoint/$id');
    return fromJson(ApiClient.decode(response));
  }

  Future<T> insert(dynamic request) async {
    final response = await ApiClient.post(endpoint, body: request);
    return fromJson(ApiClient.decode(response));
  }

  Future<T> update(int id, dynamic request) async {
    final response = await ApiClient.put('$endpoint/$id', body: request);
    return fromJson(ApiClient.decode(response));
  }

  Future<void> delete(int id) async {
    await ApiClient.delete('$endpoint/$id');
  }

  Future<dynamic> getRaw(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    final response = await ApiClient.get(path, query: query);
    return ApiClient.decode(response);
  }

  /// postRaw koji ne puca na 204 No Content
  Future<dynamic> postRaw(String path, dynamic body) async {
    final response = await ApiClient.post(path, body: body);
    // 204 No Content — vrati null, ne pokušavaj parsirati prazan body
    if (response.statusCode == 204) return null;
    return ApiClient.decode(response);
  }

  /// putRaw koji ne puca na 204 No Content
  Future<dynamic> putRaw(String path, dynamic body) async {
    final response = await ApiClient.put(path, body: body);
    if (response.statusCode == 204) return null;
    return ApiClient.decode(response);
  }

  Future<dynamic> deleteRaw(String path) async {
    final response = await ApiClient.delete(path);
    if (response.statusCode == 204) return null;
    return ApiClient.decode(response);
  }

  T fromJson(dynamic data);
}