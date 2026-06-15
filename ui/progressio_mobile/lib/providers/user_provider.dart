import 'package:progressio_mobile/core/api_client.dart';
import 'package:progressio_mobile/model/search_result.dart';
import 'package:progressio_mobile/model/user.dart';
import 'package:progressio_mobile/model/user_search_item.dart';
import 'package:progressio_mobile/providers/base_provider.dart';

class UserProvider extends BaseProvider<AppUser> {
  UserProvider() : super('users');

  @override
  AppUser fromJson(dynamic json) => AppUser.fromJson(json);

  Future<AppUser> getMe() async {
    final data = await getRaw('auth/me');
    return AppUser.fromJson(data);
  }

  Future<AppUser> updateProfile({
    required String firstName,
    required String lastName,
    required String email,
  }) async {
    final data = await putRaw('auth/profile', {
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      'email': email.trim(),
    });
    return AppUser.fromJson(data);
  }

  Future<String> uploadProfileImage(String filePath) async {
    final response = await ApiClient.uploadFile(
      'auth/profile-image',
      fieldName: 'file',
      filePath: filePath,
    );
    final data = ApiClient.decode(response) as Map<String, dynamic>;
    return data['profileImageUrl'] as String? ?? '';
  }

  Future<SearchResult<UserSearchItem>> searchUsers(
    String query, {
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await ApiClient.get(
      'users/search',
      query: {
        'query': query.trim(),
        'page': page,
        'pageSize': pageSize,
      },
    );
    final data = ApiClient.decode(response) as Map<String, dynamic>;
    return SearchResult<UserSearchItem>()
      ..totalCount = data['totalCount'] as int? ?? 0
      ..items = (data['items'] as List<dynamic>? ?? const [])
          .map((item) => UserSearchItem.fromJson(
                Map<String, dynamic>.from(item as Map),
              ))
          .toList();
  }

  Future<AppUser> getProfile(int userId) async {
    final data = await getRaw('users/$userId/profile');
    return AppUser.fromJson(data);
  }

  Future<void> follow(int userId) async {
    await postRaw('users/$userId/follow', {});
  }

  Future<void> unfollow(int userId) async {
    await deleteRaw('users/$userId/follow');
  }
     Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await postRaw('auth/change-password', {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }
}
