class UserProgress {
  final int id;
  final int contentId;
  final String contentTitle;
  final String? coverImageUrl;
  final String? contentTypeName;
  final String status;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? lastActivityAt;
  final String? cancelledReason;

  UserProgress({
    this.id = 0,
    this.contentId = 0,
    this.contentTitle = '',
    this.coverImageUrl,
    this.contentTypeName,
    this.status = 'InProgress',
    this.startedAt,
    this.completedAt,
    this.lastActivityAt,
    this.cancelledReason,
  });

  factory UserProgress.fromJson(Map<String, dynamic> json) {
    return UserProgress(
      id: json['id'] ?? 0,
      contentId: json['contentId'] ?? 0,
      contentTitle: json['contentTitle'] ?? '',
      coverImageUrl: json['coverImageUrl'],
      contentTypeName: json['contentTypeName'],
      status: json['status'] ?? 'InProgress',
      startedAt: json['startedAt'] != null ? DateTime.parse(json['startedAt']) : null,
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
      lastActivityAt: json['lastActivityAt'] != null ? DateTime.parse(json['lastActivityAt']) : null,
      cancelledReason: json['cancelledReason'],
    );
  }
}