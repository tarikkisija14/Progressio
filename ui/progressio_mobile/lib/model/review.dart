class Review {
  final int id;
  final int userId;
  final String? username;
  final String? userProfileImageUrl;
  final int contentId;
  final int rating;
  final String? title;
  final String? body;
  final bool hasSpoiler;
  final int likeCount;
  final bool isVisible;
  final DateTime createdAt;

  Review({
    this.id = 0,
    this.userId = 0,
    this.username,
    this.userProfileImageUrl,
    this.contentId = 0,
    this.rating = 0,
    this.title,
    this.body,
    this.hasSpoiler = false,
    this.likeCount = 0,
    this.isVisible = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? 0,
      username: json['username'],
      userProfileImageUrl: json['userProfileImageUrl'],
      contentId: json['contentId'] ?? 0,
      rating: json['rating'] ?? 0,
      title: json['title'],
      body: json['body'],
      hasSpoiler: json['hasSpoiler'] ?? false,
      likeCount: json['likeCount'] ?? 0,
      isVisible: json['isVisible'] ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}