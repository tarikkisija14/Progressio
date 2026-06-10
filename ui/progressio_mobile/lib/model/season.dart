class Season {
  final int id;
  final int contentId;
  final String? contentTitle;
  final int seasonNumber;
  final String title;
  final int episodeCount;
  final int? releaseYear;

  Season({
    this.id = 0,
    this.contentId = 0,
    this.contentTitle,
    this.seasonNumber = 1,
    this.title = '',
    this.episodeCount = 0,
    this.releaseYear,
  });

  factory Season.fromJson(Map<String, dynamic> json) {
    return Season(
      id: json['id'] ?? 0,
      contentId: json['contentId'] ?? 0,
      contentTitle: json['contentTitle'],
      seasonNumber: json['seasonNumber'] ?? 1,
      title: json['title'] ?? '',
      episodeCount: json['episodeCount'] ?? 0,
      releaseYear: json['releaseYear'],
    );
  }
}