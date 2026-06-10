class BasicStats {
  final int totalCompleted;
  final int totalInProgress;
  final int totalCancelled;

  BasicStats({
    this.totalCompleted = 0,
    this.totalInProgress = 0,
    this.totalCancelled = 0,
  });

  factory BasicStats.fromJson(Map<String, dynamic> json) {
    return BasicStats(
      totalCompleted: json['totalCompleted'] ?? 0,
      totalInProgress: json['totalInProgress'] ?? 0,
      totalCancelled: json['totalCancelled'] ?? 0,
    );
  }
}

class PremiumStats {
  final double totalWatchHours;
  final double totalReadHours;
  final double totalGameHours;
  final int currentStreak;
  final int longestStreak;
  final List<GenreStats> topGenres;
  final List<HeatmapEntry> heatmap;

  PremiumStats({
    this.totalWatchHours = 0,
    this.totalReadHours = 0,
    this.totalGameHours = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    List<GenreStats>? topGenres,
    List<HeatmapEntry>? heatmap,
  })  : topGenres = topGenres ?? [],
        heatmap = heatmap ?? [];

  factory PremiumStats.fromJson(Map<String, dynamic> json) {
    return PremiumStats(
      totalWatchHours: (json['totalWatchHours'] ?? 0).toDouble(),
      totalReadHours: (json['totalReadHours'] ?? 0).toDouble(),
      totalGameHours: (json['totalGameHours'] ?? 0).toDouble(),
      currentStreak: json['currentStreak'] ?? 0,
      longestStreak: json['longestStreak'] ?? 0,
      topGenres: json['topGenres'] != null
          ? (json['topGenres'] as List).map((e) => GenreStats.fromJson(e)).toList()
          : [],
      heatmap: json['heatmap'] != null
          ? (json['heatmap'] as List).map((e) => HeatmapEntry.fromJson(e)).toList()
          : [],
    );
  }
}

class GenreStats {
  final String genreName;
  final int completedCount;
  final double completionRate;

  GenreStats({
    this.genreName = '',
    this.completedCount = 0,
    this.completionRate = 0,
  });

  factory GenreStats.fromJson(Map<String, dynamic> json) {
    return GenreStats(
      genreName: json['genreName'] ?? '',
      completedCount: json['completedCount'] ?? 0,
      completionRate: (json['completionRate'] ?? 0).toDouble(),
    );
  }
}

class HeatmapEntry {
  final DateTime date;
  final int count;

  HeatmapEntry({required this.date, this.count = 0});

  factory HeatmapEntry.fromJson(Map<String, dynamic> json) {
    return HeatmapEntry(
      date: DateTime.parse(json['date']),
      count: json['count'] ?? 0,
    );
  }
}