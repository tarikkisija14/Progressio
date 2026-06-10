class Review {
  final int id;
  final int userId;
  final String userFullName;
  final String? userProfileImageUrl;
  final int contentId;
  final String contentTitle;
  final int rating;
  final String? title;
  final String? body;
  final bool hasSpoiler;
  final DateTime createdAt;
  final bool isVisible;
  final int likeCount;

  Review({
    this.id = 0,
    this.userId = 0,
    this.userFullName = '',
    this.userProfileImageUrl,
    this.contentId = 0,
    this.contentTitle = '',
    this.rating = 0,
    this.title,
    this.body,
    this.hasSpoiler = false,
    DateTime? createdAt,
    this.isVisible = true,
    this.likeCount = 0,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? 0,
      userFullName: json['userFullName'] ?? '',
      userProfileImageUrl: json['userProfileImageUrl'],
      contentId: json['contentId'] ?? 0,
      contentTitle: json['contentTitle'] ?? '',
      rating: json['rating'] ?? 0,
      title: json['title'],
      body: json['body'],
      hasSpoiler: json['hasSpoiler'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      isVisible: json['isVisible'] ?? true,
      likeCount: json['likeCount'] ?? 0,
    );
  }
}