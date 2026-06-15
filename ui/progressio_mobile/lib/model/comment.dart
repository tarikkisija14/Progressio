class Comment {
  final int id;
  final int userId;
  final String? userFullName;
  final String? username;
  final String? userProfileImageUrl;
  final int contentId;
  final int? episodeId;
  final String? episodeTitle;
  final int? chapterId;
  final String? chapterTitle;
  final String text;
  final bool hasSpoiler;
  final int likeCount;
  final bool isVisible;
  final bool isDeleted;
  final DateTime createdAt;
  final bool isLikedByCurrentUser;

  // aliasi za stare screenove
  String get content => text;
  bool get isSpoiler => hasSpoiler;
  int get likesCount => likeCount;

  Comment({
    this.id = 0,
    this.userId = 0,
    this.userFullName,
    this.username,
    this.userProfileImageUrl,
    this.contentId = 0,
    this.episodeId,
    this.episodeTitle,
    this.chapterId,
    this.chapterTitle,
    this.text = '',
    this.hasSpoiler = false,
    this.likeCount = 0,
    this.isVisible = true,
    this.isDeleted = false,
    DateTime? createdAt,
    this.isLikedByCurrentUser = false,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? 0,
      userFullName: json['userFullName'],
      username: json['username'],
      userProfileImageUrl: json['userProfileImageUrl'],
      contentId: json['contentId'] ?? 0,
      episodeId: json['episodeId'],
      episodeTitle: json['episodeTitle'],
      chapterId: json['chapterId'],
      chapterTitle: json['chapterTitle'],
      text: json['text'] ?? json['content'] ?? '',
      hasSpoiler: json['hasSpoiler'] ?? json['isSpoiler'] ?? false,
      likeCount: json['likeCount'] ?? json['likesCount'] ?? 0,
      isVisible: json['isVisible'] ?? true,
      isDeleted: json['isDeleted'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      isLikedByCurrentUser: json['isLikedByCurrentUser'] ?? false,
    );
  }
}