import 'package:progressio_mobile/core/api_config.dart';

class AppUser {
  final int id;
  final String firstName;
  final String lastName;
  final String username;
  final String email;
  final String? profileImageUrl;
  final bool isProfilePublic;
  final bool isActive;
  final bool isPremium;
  final String? activePlanType;
  final DateTime createdAt;
  final int totalCompleted;
  final int totalInProgress;
  final bool isFollowedByCurrentUser;  
  final int followerCount;             
  final int followingCount;            

  AppUser({
    this.id = 0,
    this.firstName = '',
    this.lastName = '',
    this.username = '',
    this.email = '',
    this.profileImageUrl,
    this.isProfilePublic = true,
    this.isActive = true,
    this.isPremium = false,
    this.activePlanType,
    DateTime? createdAt,
    this.totalCompleted = 0,
    this.totalInProgress = 0,
    this.isFollowedByCurrentUser = false,  
    this.followerCount = 0,                
    this.followingCount = 0,               
  }) : createdAt = createdAt ?? DateTime.now();

  String get fullName => '$firstName $lastName'.trim();

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] ?? 0,
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      profileImageUrl: ApiConfig.resolveResource(json['profileImageUrl'] as String?),
      isProfilePublic: json['isProfilePublic'] ?? true,
      isActive: json['isActive'] ?? true,
      isPremium: json['isPremium'] ?? false,
      activePlanType: json['activePlanType'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      totalCompleted: json['totalCompleted'] ?? 0,
      totalInProgress: json['totalInProgress'] ?? 0,
      isFollowedByCurrentUser: json['isFollowedByCurrentUser'] ?? false,  
      followerCount: json['followerCount'] ?? 0,                          
      followingCount: json['followingCount'] ?? 0,                        
    );
  }
}