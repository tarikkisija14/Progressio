import 'package:progressio_mobile/model/user_list.dart';
import 'package:progressio_mobile/providers/base_provider.dart';

class UserListProvider extends BaseProvider<UserList> {
  UserListProvider() : super('lists');

  @override
  UserList fromJson(dynamic json) => UserList.fromJson(json);

  Future<List<UserList>> getMyLists() async {
    final result = await get(filter: {'page': 1, 'pageSize': 50});
    return result.items;
  }

  Future<List<UserList>> getPublicLists({String? search}) async {
    final filter = <String, dynamic>{'page': 1, 'pageSize': 20};
    if (search != null && search.isNotEmpty) filter['search'] = search;
    final data = await getRaw('lists/public', query: filter);
    if (data is Map && data['items'] != null) {
      return (data['items'] as List).map((e) => UserList.fromJson(e)).toList();
    }
    return [];
  }

  Future<void> forkList(int listId) async {
    await postRaw('lists/$listId/fork', {});
  }

  Future<void> inviteUser(int listId, int userId) async {
    await postRaw('lists/$listId/invite/$userId', {});
  }

  Future<void> addContent(int listId, int contentId) async {
    await postRaw('lists/$listId/items', {'contentId': contentId});
  }

  Future<void> removeContent(int listId, int contentId) async {
    await deleteRaw('lists/$listId/items/$contentId');
  }
}