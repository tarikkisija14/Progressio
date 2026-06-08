class AppUser {
  final int id;
  final String firstName;
  final String lastName;
  final String username;
  final String email;
  final String? profileImageUrl;
  final bool isProfilePublic;
  final bool isPremium;
  final DateTime createdAt;

  AppUser({
    this.id = 0,
    this.firstName = '',
    this.lastName = '',
    this.username = '',
    this.email = '',
    this.profileImageUrl,
    this.isProfilePublic = true,
    this.isPremium = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String get fullName => '$firstName $lastName'.trim();

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] ?? 0,
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      profileImageUrl: json['profileImageUrl'],
      isProfilePublic: json['isProfilePublic'] ?? true,
      isPremium: json['isPremium'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}