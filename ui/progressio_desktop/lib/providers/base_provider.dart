import 'package:flutter/material.dart';
import 'package:progressio_desktop/core/api_client.dart';
import 'package:progressio_desktop/model/search_result.dart';

abstract class BaseProvider<T> with ChangeNotifier {
  final String endpoint;

  BaseProvider(this.endpoint);

  Future<SearchResult<T>> get({dynamic filter}) async {
    final response = await ApiClient.get(
      endpoint,
      query: filter is Map<String, dynamic> ? filter : null,
    );
    final data = ApiClient.decode(response) as Map<String, dynamic>;
    return SearchResult<T>()
      ..totalCount = data['totalCount'] as int? ?? 0
      ..items = (data['items'] as List<dynamic>? ?? const []).map(fromJson).toList();
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
      final pageItems = result.items ?? <T>[];
      items.addAll(pageItems);

      final totalCount = result.totalCount ?? items.length;
      if (pageItems.isEmpty || items.length >= totalCount) break;
      page++;
    }

    return items;
  }

  Future<T> getById(int id) async =>
      fromJson(ApiClient.decode(await ApiClient.get('$endpoint/$id')));

  Future<T> insert(dynamic request) async =>
      fromJson(ApiClient.decode(await ApiClient.post(endpoint, body: request)));

  Future<T> update(int id, dynamic request) async =>
      fromJson(ApiClient.decode(await ApiClient.put('$endpoint/$id', body: request)));

  Future<void> delete(int id) async {
    await ApiClient.delete('$endpoint/$id');
  }

  Future<dynamic> getRaw(String path, {Map<String, dynamic>? query}) async =>
      ApiClient.decode(await ApiClient.get(path, query: query));

  Future<dynamic> postRaw(String path, dynamic body) async =>
      ApiClient.decode(await ApiClient.post(path, body: body));

  T fromJson(dynamic data);
}
