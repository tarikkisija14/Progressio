import 'package:progressio_desktop/model/user.dart';
import 'package:progressio_desktop/providers/base_provider.dart';

// NOTE: Backend does not expose a GET /api/users (admin list) endpoint.
// The getProfile method uses GET /api/users/{id}/profile which exists.
// A proper admin user listing endpoint (GET /api/admin/users) is required
// on the backend for full functionality.
class UserProvider extends BaseProvider<AppUser> {
  UserProvider() : super('users');

  @override
  AppUser fromJson(dynamic json) => AppUser.fromJson(json);

  Future<AppUser> getProfile(int userId) async {
    final data = await getRaw('users/$userId/profile');
    return AppUser.fromJson(data);
  }
}