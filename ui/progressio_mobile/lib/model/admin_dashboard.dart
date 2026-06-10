class TopContentItem {
  final int contentId;
  final String title;
  final String contentType;
  final double avgRating;
  final int followerCount;
  final List<String> genres;

  TopContentItem({
    this.contentId = 0,
    this.title = '',
    this.contentType = '',
    this.avgRating = 0,
    this.followerCount = 0,
    List<String>? genres,
  }) : genres = genres ?? [];

  factory TopContentItem.fromJson(Map<String, dynamic> json) {
    return TopContentItem(
      contentId: json['contentId'] ?? 0,
      title: json['title'] ?? '',
      contentType: json['contentType'] ?? '',
      avgRating: (json['avgRating'] ?? 0).toDouble(),
      followerCount: json['followerCount'] ?? 0,
      genres: json['genres'] != null
          ? List<String>.from(json['genres'])
          : [],
    );
  }
}

class PeriodUserCount {
  final String period;
  final int count;

  PeriodUserCount({this.period = '', this.count = 0});

  factory PeriodUserCount.fromJson(Map<String, dynamic> json) {
    return PeriodUserCount(
      period: json['period'] ?? '',
      count: json['count'] ?? 0,
    );
  }
}

class NewUsersData {
  final List<PeriodUserCount> byWeek;
  final List<PeriodUserCount> byMonth;

  NewUsersData({List<PeriodUserCount>? byWeek, List<PeriodUserCount>? byMonth})
      : byWeek = byWeek ?? [],
        byMonth = byMonth ?? [];

  factory NewUsersData.fromJson(Map<String, dynamic> json) {
    return NewUsersData(
      byWeek: json['byWeek'] != null
          ? (json['byWeek'] as List)
              .map((e) => PeriodUserCount.fromJson(e))
              .toList()
          : [],
      byMonth: json['byMonth'] != null
          ? (json['byMonth'] as List)
              .map((e) => PeriodUserCount.fromJson(e))
              .toList()
          : [],
    );
  }
}

class ActiveUsersData {
  final int activeLast7Days;

  ActiveUsersData({this.activeLast7Days = 0});

  factory ActiveUsersData.fromJson(Map<String, dynamic> json) {
    return ActiveUsersData(
      activeLast7Days: json['activeLast7Days'] ?? 0,
    );
  }
}

class UpcomingReleaseItem {
  final int id;
  final String title;
  final String contentTitle;
  final int contentId;
  final String itemType;
  final DateTime releaseDate;
  final int? seasonNumber;
  final int? episodeNumber;
  final int? chapterNumber;

  UpcomingReleaseItem({
    this.id = 0,
    this.title = '',
    this.contentTitle = '',
    this.contentId = 0,
    this.itemType = '',
    DateTime? releaseDate,
    this.seasonNumber,
    this.episodeNumber,
    this.chapterNumber,
  }) : releaseDate = releaseDate ?? DateTime.now();

  factory UpcomingReleaseItem.fromJson(Map<String, dynamic> json) {
    return UpcomingReleaseItem(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      contentTitle: json['contentTitle'] ?? '',
      contentId: json['contentId'] ?? 0,
      itemType: json['itemType'] ?? '',
      releaseDate: json['releaseDate'] != null
          ? DateTime.parse(json['releaseDate'])
          : DateTime.now(),
      seasonNumber: json['seasonNumber'],
      episodeNumber: json['episodeNumber'],
      chapterNumber: json['chapterNumber'],
    );
  }
}

class AchievementEarnItem {
  final int achievementId;
  final String code;
  final String name;
  final int earnedCount;

  AchievementEarnItem({
    this.achievementId = 0,
    this.code = '',
    this.name = '',
    this.earnedCount = 0,
  });

  factory AchievementEarnItem.fromJson(Map<String, dynamic> json) {
    return AchievementEarnItem(
      achievementId: json['achievementId'] ?? 0,
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      earnedCount: json['earnedCount'] ?? 0,
    );
  }
}

class AchievementStatsData {
  final List<AchievementEarnItem> topAchievements;

  AchievementStatsData({List<AchievementEarnItem>? topAchievements})
      : topAchievements = topAchievements ?? [];

  factory AchievementStatsData.fromJson(Map<String, dynamic> json) {
    return AchievementStatsData(
      topAchievements: json['topAchievements'] != null
          ? (json['topAchievements'] as List)
              .map((e) => AchievementEarnItem.fromJson(e))
              .toList()
          : [],
    );
  }
}

class AdminDashboard {
  final List<TopContentItem> topContent;
  final NewUsersData newUsers;
  final ActiveUsersData activeUsers;
  final List<UpcomingReleaseItem> upcomingReleases;
  final AchievementStatsData achievementStats;

  AdminDashboard({
    List<TopContentItem>? topContent,
    NewUsersData? newUsers,
    ActiveUsersData? activeUsers,
    List<UpcomingReleaseItem>? upcomingReleases,
    AchievementStatsData? achievementStats,
  })  : topContent = topContent ?? [],
        newUsers = newUsers ?? NewUsersData(),
        activeUsers = activeUsers ?? ActiveUsersData(),
        upcomingReleases = upcomingReleases ?? [],
        achievementStats = achievementStats ?? AchievementStatsData();

  factory AdminDashboard.fromJson(Map<String, dynamic> json) {
    return AdminDashboard(
      topContent: json['topContent'] != null
          ? (json['topContent'] as List)
              .map((e) => TopContentItem.fromJson(e))
              .toList()
          : [],
      newUsers: json['newUsers'] != null
          ? NewUsersData.fromJson(json['newUsers'])
          : NewUsersData(),
      activeUsers: json['activeUsers'] != null
          ? ActiveUsersData.fromJson(json['activeUsers'])
          : ActiveUsersData(),
      upcomingReleases: json['upcomingReleases'] != null
          ? (json['upcomingReleases'] as List)
              .map((e) => UpcomingReleaseItem.fromJson(e))
              .toList()
          : [],
      achievementStats: json['achievementStats'] != null
          ? AchievementStatsData.fromJson(json['achievementStats'])
          : AchievementStatsData(),
    );
  }
}