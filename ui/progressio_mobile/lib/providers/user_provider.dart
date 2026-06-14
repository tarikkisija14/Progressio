import 'package:progressio_mobile/model/user.dart';
import 'package:progressio_mobile/providers/base_provider.dart';

class UserProvider extends BaseProvider<AppUser> {
  UserProvider() : super('users');

  @override
  AppUser fromJson(dynamic json) => AppUser.fromJson(json);

  Future<AppUser> getMe() async {
    final data = await getRaw('auth/me');
    return AppUser.fromJson(data);
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
}