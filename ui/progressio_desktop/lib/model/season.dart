class Season {
  final int id;
  final int contentId;
  final String? contentTitle;
  final int seasonNumber;
  final String? title;
  final int? releaseYear;
  final int episodeCount;

  Season({
    this.id = 0,
    this.contentId = 0,
    this.contentTitle,
    this.seasonNumber = 1,
    this.title,
    this.releaseYear,
    this.episodeCount = 0,
  });

  factory Season.fromJson(Map<String, dynamic> json) {
    return Season(
      id: json['id'] ?? 0,
      contentId: json['contentId'] ?? 0,
      contentTitle: json['contentTitle'],
      seasonNumber: json['seasonNumber'] ?? 1,
      title: json['title'],
      releaseYear: json['releaseYear'],
      episodeCount: json['episodeCount'] ?? 0,
    );
  }
}