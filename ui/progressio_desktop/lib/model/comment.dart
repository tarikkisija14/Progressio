class Comment {
  final int id;
  final int userId;
  final String? username;
  final int episodeId;
  final String? episodeTitle;
  final String content;
  final bool isSpoiler;
  final bool isVisible;
  final bool isDeleted;
  final int likesCount;
  final DateTime createdAt;

  Comment({
    this.id = 0,
    this.userId = 0,
    this.username,
    this.episodeId = 0,
    this.episodeTitle,
    this.content = '',
    this.isSpoiler = false,
    this.isVisible = true,
    this.isDeleted = false,
    this.likesCount = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? 0,
      username: json['username'],
      episodeId: json['episodeId'] ?? 0,
      episodeTitle: json['episodeTitle'],
      content: json['content'] ?? '',
      isSpoiler: json['isSpoiler'] ?? false,
      isVisible: json['isVisible'] ?? true,
      isDeleted: json['isDeleted'] ?? false,
      likesCount: json['likesCount'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}