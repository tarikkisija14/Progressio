import 'package:progressio_desktop/model/user.dart';
import 'package:progressio_desktop/providers/base_provider.dart';

class UserProvider extends BaseProvider<AppUser> {
  UserProvider() : super('admin/users');

  @override
  AppUser fromJson(dynamic json) => AppUser.fromJson(json);

  Future<AppUser> getProfile(int userId) async {
    final data = await getRaw('users/$userId/profile');
    return AppUser.fromJson(data);
  }
}