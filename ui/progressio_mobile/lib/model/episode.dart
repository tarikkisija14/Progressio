

class Episode {
  final int id;
  final int seasonId;
  final int episodeNumber;
  final String title;
  final int? durationMinutes;
  final DateTime airDate;

  Episode({
    this.id = 0,
    this.seasonId = 0,
    this.episodeNumber = 1,
    this.title = '',
    this.durationMinutes,
    DateTime? airDate,
  }) : airDate = airDate ?? DateTime.now();

  factory Episode.fromJson(Map<String, dynamic> json) {
    return Episode(
      id: json['id'] ?? 0,
      seasonId: json['seasonId'] ?? 0,
      episodeNumber: json['episodeNumber'] ?? 1,
      title: json['title'] ?? '',
      durationMinutes: json['durationMinutes'],
      airDate: json['airDate'] != null
          ? DateTime.parse(json['airDate'])
          : DateTime.now(),
    );
  }
}