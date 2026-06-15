import 'package:progressio_mobile/core/api_config.dart';

class UserSearchItem {
  final int id;
  final String firstName;
  final String lastName;
  final String username;
  final String? profileImageUrl;
  final bool isProfilePublic;
  final bool isFollowedByCurrentUser;

  const UserSearchItem({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.username,
    this.profileImageUrl,
    required this.isProfilePublic,
    required this.isFollowedByCurrentUser,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory UserSearchItem.fromJson(Map<String, dynamic> json) {
    return UserSearchItem(
      id: json['id'] as int? ?? 0,
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      username: json['username'] as String? ?? '',
      profileImageUrl:
          ApiConfig.resolveResource(json['profileImageUrl'] as String?),
      isProfilePublic: json['isProfilePublic'] as bool? ?? true,
      isFollowedByCurrentUser:
          json['isFollowedByCurrentUser'] as bool? ?? false,
    );
  }

  UserSearchItem copyWith({bool? isFollowedByCurrentUser}) {
    return UserSearchItem(
      id: id,
      firstName: firstName,
      lastName: lastName,
      username: username,
      profileImageUrl: profileImageUrl,
      isProfilePublic: isProfilePublic,
      isFollowedByCurrentUser:
          isFollowedByCurrentUser ?? this.isFollowedByCurrentUser,
    );
  }
}