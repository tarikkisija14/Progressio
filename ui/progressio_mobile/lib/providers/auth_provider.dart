class AuthProvider {
  static String? token;
  static String? refreshToken;
  static String? username;
  static String? password;
  static int? userId;
  static bool isPremium = false;
  static String? userRole;

 
  static int? get currentUserId => userId;

  static bool get isLoggedIn => token != null && token!.isNotEmpty;

  static void clear() {
    token = null;
    refreshToken = null;
    username = null;
    password = null;
    userId = null;
    isPremium = false;
    userRole = null;
  }
}