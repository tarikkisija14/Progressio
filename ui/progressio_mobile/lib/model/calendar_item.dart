class CalendarItem {
  final String title;
  final String contentTitle;
  final String itemType;
  final DateTime releaseDate;
  final String? coverImageUrl;
  final int? seasonNumber;
  final int? episodeNumber;
  final int? chapterNumber;
  final int contentId;

  CalendarItem({
    this.title = '',
    this.contentTitle = '',
    this.itemType = '',
    required this.releaseDate,
    this.coverImageUrl,
    this.seasonNumber,
    this.episodeNumber,
    this.chapterNumber,
    this.contentId = 0,
  });

  factory CalendarItem.fromJson(Map<String, dynamic> json) {
    return CalendarItem(
      title: json['title'] ?? '',
      contentTitle: json['contentTitle'] ?? '',
      itemType: json['itemType'] ?? '',
      releaseDate: json['releaseDate'] != null
          ? DateTime.parse(json['releaseDate'])
          : DateTime.now(),
      coverImageUrl: json['coverImageUrl'],
      seasonNumber: json['seasonNumber'],
      episodeNumber: json['episodeNumber'],
      chapterNumber: json['chapterNumber'],
      contentId: json['contentId'] ?? 0,
    );
  }

  String get releaseDetails {
    if (seasonNumber != null && episodeNumber != null) return 'S$seasonNumber E$episodeNumber';
    if (chapterNumber != null) return 'Ch. $chapterNumber';
    return '';
  }
}