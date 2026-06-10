

class FeedItem {
  final String activityType;
  final int actorUserId;
  final String actorFullName;
  final String? actorProfileImageUrl;
  final int? contentId;
  final String? contentTitle;
  final String? contentCoverImageUrl;
  final int? achievementId;
  final String? achievementName;
  final int? userListId;
  final String? userListName;
  final int? reviewId;
  final int? reviewRating;
  final DateTime occurredAt;

  FeedItem({
    this.activityType = '',
    this.actorUserId = 0,
    this.actorFullName = '',
    this.actorProfileImageUrl,
    this.contentId,
    this.contentTitle,
    this.contentCoverImageUrl,
    this.achievementId,
    this.achievementName,
    this.userListId,
    this.userListName,
    this.reviewId,
    this.reviewRating,
    DateTime? occurredAt,
  }) : occurredAt = occurredAt ?? DateTime.now();

  factory FeedItem.fromJson(Map<String, dynamic> json) {
    return FeedItem(
      activityType: json['activityType']?.toString() ?? '',
      actorUserId: json['actorUserId'] ?? 0,
      actorFullName: json['actorFullName'] ?? '',
      actorProfileImageUrl: json['actorProfileImageUrl'],
      contentId: json['contentId'],
      contentTitle: json['contentTitle'],
      contentCoverImageUrl: json['contentCoverImageUrl'],
      achievementId: json['achievementId'],
      achievementName: json['achievementName'],
      userListId: json['userListId'],
      userListName: json['userListName'],
      reviewId: json['reviewId'],
      reviewRating: json['reviewRating'],
      occurredAt: json['occurredAt'] != null
          ? DateTime.parse(json['occurredAt'])
          : DateTime.now(),
    );
  }
}