class FeedItem {
  final int id;
  final int userId;
  final String username;
  final String? userProfileImageUrl;
  final String activityType;
  final String? contentTitle;
  final String? coverImageUrl;
  final int? contentId;
  final String? extraText;
  final DateTime createdAt;

  FeedItem({
    this.id = 0,
    this.userId = 0,
    this.username = '',
    this.userProfileImageUrl,
    this.activityType = '',
    this.contentTitle,
    this.coverImageUrl,
    this.contentId,
    this.extraText,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory FeedItem.fromJson(Map<String, dynamic> json) {
    return FeedItem(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? 0,
      username: json['username'] ?? '',
      userProfileImageUrl: json['userProfileImageUrl'],
      activityType: json['activityType'] ?? '',
      contentTitle: json['contentTitle'],
      coverImageUrl: json['coverImageUrl'],
      contentId: json['contentId'],
      extraText: json['extraText'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}