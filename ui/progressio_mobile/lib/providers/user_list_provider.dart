import 'package:progressio_mobile/model/user_list.dart';
import 'package:progressio_mobile/providers/base_provider.dart';

class UserListProvider extends BaseProvider<UserList> {
  UserListProvider() : super('lists');

  @override
  UserList fromJson(dynamic json) => UserList.fromJson(json);

  /// GET /api/lists?page=1&pageSize=50
  Future<List<UserList>> getMyLists({String? search}) async {
    final filter = <String, dynamic>{};
    if (search != null && search.isNotEmpty) filter['search'] = search;
    return getAll(filter: filter);
  }

  /// GET /api/lists/public?page=1&pageSize=20&search=
  Future<List<UserList>> getPublicLists(
      {String? search, int page = 1}) async {
    final filter = <String, dynamic>{'page': page, 'pageSize': 20};
    if (search != null && search.isNotEmpty) filter['search'] = search;
    final data = await getRaw('lists/public', query: filter);
    if (data is Map && data['items'] != null) {
      return (data['items'] as List)
          .map((e) => UserList.fromJson(e))
          .toList();
    }
    return [];
  }

  /// POST /api/lists
  Future<UserList> createList({
    required String name,
    String? description,
    bool isPublic = false,
    bool isShared = false,
  }) async {
    final data = await postRaw('lists', {
      'name': name,
      if (description != null) 'description': description,
      'isPublic': isPublic,
      'isShared': isShared,
    });
    return UserList.fromJson(data);
  }

  /// PUT /api/lists/{id}
  Future<UserList> updateList(
    int id, {
    required String name,
    String? description,
    bool isPublic = false,
    bool isShared = false,
  }) async {
    final data = await putRaw('lists/$id', {
      'name': name,
      if (description != null) 'description': description,
      'isPublic': isPublic,
      'isShared': isShared,
    });
    return UserList.fromJson(data);
  }

  /// DELETE /api/lists/{id}
  Future<void> deleteList(int id) async {
    await deleteRaw('lists/$id');
  }

  /// GET /api/lists/{id}/items?page=1&pageSize=50
  Future<List<UserListItem>> getListItems(int listId,
      {int page = 1}) async {
    final data = await getRaw('lists/$listId/items',
        query: {'page': page, 'pageSize': 50});
    if (data is Map && data['items'] != null) {
      return (data['items'] as List)
          .map((e) => UserListItem.fromJson(e))
          .toList();
    }
    return [];
  }

  /// POST /api/lists/{id}/items  body: { contentId, priority }
  Future<void> addContent(int listId, int contentId,
      {String priority = 'Medium'}) async {
    await postRaw('lists/$listId/items', {
      'contentId': contentId,
      'priority': priority,
    });
  }

  /// DELETE /api/lists/{id}/items/{contentId}
  Future<void> removeContent(int listId, int contentId) async {
    await deleteRaw('lists/$listId/items/$contentId');
  }

  /// POST /api/lists/{id}/fork
  Future<UserList> forkList(int listId) async {
    final data = await postRaw('lists/$listId/fork', {});
    return UserList.fromJson(data);
  }

  /// POST /api/lists/{id}/invite/{userId}
  Future<void> inviteUser(int listId, int userId) async {
    await postRaw('lists/$listId/invite/$userId', {});
  }

  /// POST /api/lists/{id}/accept
  Future<void> acceptInvite(int listId) async {
    await postRaw('lists/$listId/accept', {});
  }

  /// POST /api/lists/{id}/decline
  Future<void> declineInvite(int listId) async {
    await postRaw('lists/$listId/decline', {});
  }

  /// DELETE /api/lists/{id}/leave
  Future<void> leaveList(int listId) async {
    await deleteRaw('lists/$listId/leave');
  }

  /// GET /api/lists/{id}/members
  Future<List<UserListMember>> getMembers(int listId) async {
    final data = await getRaw(
      'lists/$listId/members',
      query: {'page': 1, 'pageSize': 100},
    );
    final list = data is List ? data : (data['items'] ?? []);
    return (list as List).map((e) => UserListMember.fromJson(e)).toList();
  }
}