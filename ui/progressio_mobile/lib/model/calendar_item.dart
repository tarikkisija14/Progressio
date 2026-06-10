

class CalendarItem {
  final int id;
  final String title;
  final DateTime airDate;
  final String contentTitle;
  final int contentId;
  final String contentType;
  final String itemType;
  final int? seasonNumber;
  final int? episodeNumber;
  final int? chapterNumber;
  final int? durationMinutes;

  CalendarItem({
    this.id = 0,
    this.title = '',
    required this.airDate,
    this.contentTitle = '',
    this.contentId = 0,
    this.contentType = '',
    this.itemType = '',
    this.seasonNumber,
    this.episodeNumber,
    this.chapterNumber,
    this.durationMinutes,
  });

  factory CalendarItem.fromJson(Map<String, dynamic> json) {
    return CalendarItem(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      airDate: json['airDate'] != null
          ? DateTime.parse(json['airDate'])
          : DateTime.now(),
      contentTitle: json['contentTitle'] ?? '',
      contentId: json['contentId'] ?? 0,
      contentType: json['contentType'] ?? '',
      itemType: json['itemType'] ?? '',
      seasonNumber: json['seasonNumber'],
      episodeNumber: json['episodeNumber'],
      chapterNumber: json['chapterNumber'],
      durationMinutes: json['durationMinutes'],
    );
  }

  String get releaseDetails {
    if (seasonNumber != null && episodeNumber != null) {
      return 'S$seasonNumber E$episodeNumber';
    }
    if (chapterNumber != null) return 'Ch. $chapterNumber';
    return '';
  }
}