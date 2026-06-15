class AuthProvider {
  static String? token;
  static String? refreshToken;
  static int? userId;
  static bool isPremium = false;
  static List<String> roles = const [];

  static int? get currentUserId => userId;
  static bool get isLoggedIn => token != null && token!.isNotEmpty;
  static bool get isAdmin => roles.contains('Admin');

  static void applyLoginResponse(Map<String, dynamic> data) {
    final user = data['user'] as Map<String, dynamic>? ?? const {};
    token = data['accessToken'] as String?;
    refreshToken = data['refreshToken'] as String?;
    userId = user['id'] as int?;
    isPremium = user['isPremium'] as bool? ?? false;
    roles = (data['roles'] as List<dynamic>? ?? const [])
        .map((role) => role.toString())
        .toList(growable: false);
  }

  static void clear() {
    token = null;
    refreshToken = null;
    userId = null;
    isPremium = false;
    roles = const [];
  }
}