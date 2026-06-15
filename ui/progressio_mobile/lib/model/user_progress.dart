class UserProgress {
  final int id;
  final int userId;
  final int contentId;
  final String contentTitle;
  final String status;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? lastActivityAt;
  final String? cancelledReason;
  final int watchedEpisodesCount;
  final int totalEpisodesCount;
  final int readChaptersCount;
  final int totalChaptersCount;
  final String? contentCoverImageUrl;

  UserProgress({
    this.id = 0,
    this.userId = 0,
    this.contentId = 0,
    this.contentTitle = '',
    this.status = 'InProgress',
    this.startedAt,
    this.completedAt,
    this.lastActivityAt,
    this.cancelledReason,
    this.watchedEpisodesCount = 0,
    this.totalEpisodesCount = 0,
    this.readChaptersCount = 0,
    this.totalChaptersCount = 0,
   this.contentCoverImageUrl,
  });

 
  static const _statusNames = ['Pending', 'InProgress', 'Completed', 'Cancelled', 'OnHold'];

  static String _parseStatus(dynamic raw) {
    if (raw == null) return 'InProgress';
    if (raw is int) {
      return (raw >= 0 && raw < _statusNames.length) ? _statusNames[raw] : 'InProgress';
    }
   
    final s = raw.toString();
    if (_statusNames.contains(s)) return s;
    final idx = int.tryParse(s);
    if (idx != null && idx >= 0 && idx < _statusNames.length) return _statusNames[idx];
    return 'InProgress';
  }

  factory UserProgress.fromJson(Map<String, dynamic> json) {
    return UserProgress(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? 0,
      contentId: json['contentId'] ?? 0,
      contentTitle: json['contentTitle'] ?? '',
      status: _parseStatus(json['status']),
      startedAt: json['startedAt'] != null ? DateTime.parse(json['startedAt']) : null,
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
      lastActivityAt: json['lastActivityAt'] != null ? DateTime.parse(json['lastActivityAt']) : null,
      cancelledReason: json['cancelledReason'],
      watchedEpisodesCount: json['watchedEpisodesCount'] ?? 0,
      totalEpisodesCount: json['totalEpisodesCount'] ?? 0,
      readChaptersCount: json['readChaptersCount'] ?? 0,
      totalChaptersCount: json['totalChaptersCount'] ?? 0,
      contentCoverImageUrl: json['contentCoverImageUrl'] as String?,
    );
  }
}