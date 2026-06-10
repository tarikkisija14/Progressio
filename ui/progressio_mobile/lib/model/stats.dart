
class BasicStats {
  final int totalCompleted;
  final int totalInProgress;
  final int totalCancelled;
  final int totalOnHold;
  final int totalPending;
  final int currentStreak;
  final int longestStreak;

  BasicStats({
    this.totalCompleted = 0,
    this.totalInProgress = 0,
    this.totalCancelled = 0,
    this.totalOnHold = 0,
    this.totalPending = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
  });

  factory BasicStats.fromJson(Map<String, dynamic> json) {
    return BasicStats(
      totalCompleted: json['totalCompleted'] ?? 0,
      totalInProgress: json['totalInProgress'] ?? 0,
      totalCancelled: json['totalCancelled'] ?? 0,
      totalOnHold: json['totalOnHold'] ?? 0,
      totalPending: json['totalPending'] ?? 0,
      currentStreak: json['currentStreak'] ?? 0,
      longestStreak: json['longestStreak'] ?? 0,
    );
  }
}

class PremiumStats {
  final double totalWatchHours;
  final double totalReadHours;
  final double totalGameHours;
  final List<HoursBreakdownItem> breakdownByType;
  final List<GenreStats> topGenres;      
  final List<HeatmapEntry> heatmap;       
  final int currentStreak;
  final int longestStreak;

  PremiumStats({
    this.totalWatchHours = 0,
    this.totalReadHours = 0,
    this.totalGameHours = 0,
    List<HoursBreakdownItem>? breakdownByType,
    List<GenreStats>? topGenres,
    List<HeatmapEntry>? heatmap,
    this.currentStreak = 0,
    this.longestStreak = 0,
  })  : breakdownByType = breakdownByType ?? [],
        topGenres = topGenres ?? [],
        heatmap = heatmap ?? [];

  factory PremiumStats.fromJson(Map<String, dynamic> json) {
    return PremiumStats(
      totalWatchHours: (json['totalWatchHours'] ?? 0).toDouble(),
      totalReadHours: (json['totalReadHours'] ?? 0).toDouble(),
      totalGameHours: (json['totalGameHours'] ?? 0).toDouble(),
      breakdownByType: json['breakdownByType'] != null
          ? (json['breakdownByType'] as List)
              .map((e) => HoursBreakdownItem.fromJson(e))
              .toList()
          : [],
      topGenres: json['topGenreCompletionRates'] != null
          ? (json['topGenreCompletionRates'] as List)
              .map((e) => GenreStats.fromJson(e))
              .toList()
          : [],
      heatmap: json['activityHeatmap'] != null
          ? (json['activityHeatmap'] as List)
              .map((e) => HeatmapEntry.fromJson(e))
              .toList()
          : [],
      currentStreak: json['currentStreak'] ?? 0,
      longestStreak: json['longestStreak'] ?? 0,
    );
  }
}

class GenreStats {
  final int genreId;
  final String genreName;
  final int completedCount;
  final double completionRate;

  GenreStats({
    this.genreId = 0,
    this.genreName = '',
    this.completedCount = 0,
    this.completionRate = 0,
  });

  factory GenreStats.fromJson(Map<String, dynamic> json) {
    return GenreStats(
      genreId: json['genreId'] ?? 0,
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
      // Backend returns: { date: "2026-01-15", count: 3 }
      date: DateTime.parse(json['date']),
      count: json['count'] ?? 0,
    );
  }
}

class HoursBreakdownItem {
  final String contentType;
  final double hours;

  HoursBreakdownItem({this.contentType = '', this.hours = 0});

  factory HoursBreakdownItem.fromJson(Map<String, dynamic> json) {
    return HoursBreakdownItem(
      contentType: json['contentType'] ?? '',
      hours: (json['hours'] ?? 0).toDouble(),
    );
  }
}