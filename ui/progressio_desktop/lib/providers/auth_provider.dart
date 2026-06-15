class AuthProvider {
  static String? token;
  static String? refreshToken;
  static List<String> roles = const [];

  static bool get isAdmin => roles.contains('Admin');

  static void applyLoginResponse(Map<String, dynamic> data) {
    token = data['accessToken'] as String?;
    refreshToken = data['refreshToken'] as String?;
    roles = (data['roles'] as List<dynamic>? ?? const [])
        .map((role) => role.toString())
        .toList(growable: false);
  }

  static void clear() {
    token = null;
    refreshToken = null;
    roles = const [];
  }
}