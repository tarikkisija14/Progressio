import 'package:flutter_secure_storage/flutter_secure_storage.dart';


class AuthProvider {

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _keyRefreshToken = 'progressio_refresh_token';
  static const _keyUserId      = 'progressio_user_id';
  static const _keyIsPremium   = 'progressio_is_premium';
  static const _keyRoles       = 'progressio_roles';

  
  static String? token;
  static String? refreshToken;
  static int?    userId;
  static bool    isPremium = false;
  static List<String> roles = const [];


  static int?  get currentUserId => userId;
  static bool  get isLoggedIn    => token != null && token!.isNotEmpty;
  static bool  get isAdmin       => roles.contains('Admin');


  static Future<void> applyLoginResponse(Map<String, dynamic> data) async {
    final user = data['user'] as Map<String, dynamic>? ?? const {};

    token        = data['accessToken'] as String?;
    refreshToken = data['refreshToken'] as String?;
    userId       = user['id'] as int?;
    isPremium    = user['isPremium'] as bool? ?? false;
    roles        = (data['roles'] as List<dynamic>? ?? const [])
        .map((r) => r.toString())
        .toList(growable: false);

   
    await Future.wait([
      if (refreshToken != null)
        _storage.write(key: _keyRefreshToken, value: refreshToken),
      if (userId != null)
        _storage.write(key: _keyUserId, value: userId.toString()),
      _storage.write(key: _keyIsPremium, value: isPremium.toString()),
      _storage.write(key: _keyRoles, value: roles.join(',')),
    ]);
  }


  static Future<bool> tryRestoreSession() async {
    final stored = await Future.wait([
      _storage.read(key: _keyRefreshToken),
      _storage.read(key: _keyUserId),
      _storage.read(key: _keyIsPremium),
      _storage.read(key: _keyRoles),
    ]);

    final storedRefresh  = stored[0];
    final storedUserId   = stored[1];
    final storedPremium  = stored[2];
    final storedRoles    = stored[3];

    if (storedRefresh == null || storedRefresh.isEmpty) return false;

    
    refreshToken = storedRefresh;
    userId       = int.tryParse(storedUserId ?? '');
    isPremium    = storedPremium == 'true';
    roles        = storedRoles?.isNotEmpty == true
        ? storedRoles!.split(',')
        : const [];

    return true;
  }


  static Future<void> clear() async {
    token        = null;
    refreshToken = null;
    userId       = null;
    isPremium    = false;
    roles        = const [];

    await Future.wait([
      _storage.delete(key: _keyRefreshToken),
      _storage.delete(key: _keyUserId),
      _storage.delete(key: _keyIsPremium),
      _storage.delete(key: _keyRoles),
    ]);
  }
}