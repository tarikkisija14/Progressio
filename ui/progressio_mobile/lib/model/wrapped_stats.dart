class WrappedStats {
  final int year;
  final double totalHours;
  final int totalCompleted;
  final String? topGenre;
  final String? favoriteCharacter;
  final String? bestRatedContent;
  final String? mostProductiveMonth;

  WrappedStats({
    this.year = 0,
    this.totalHours = 0,
    this.totalCompleted = 0,
    this.topGenre,
    this.favoriteCharacter,
    this.bestRatedContent,
    this.mostProductiveMonth,
  });

  factory WrappedStats.fromJson(Map<String, dynamic> json) {
    return WrappedStats(
      year: json['year'] ?? 0,
      totalHours: (json['totalHours'] ?? 0).toDouble(),
      totalCompleted: json['totalCompleted'] ?? 0,
      topGenre: json['topGenre'],
      favoriteCharacter: json['favoriteCharacter'],
      bestRatedContent: json['bestRatedContent'],
      mostProductiveMonth: json['mostProductiveMonth'],
    );
  }
}