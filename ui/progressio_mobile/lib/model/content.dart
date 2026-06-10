class Content {
  final int id;
  final String title;
  final String? description;
  final String? coverImageUrl;
  final int contentTypeId;
  final String? contentTypeName;
  final int? ageRatingId;
  final String? ageRatingName;
  final int? languageId;
  final String? languageName;
  final int? releaseYear;
  final double avgRating;
  final int totalRatings;
  final bool isActive;
  final DateTime createdAt;
  final List<String> genres;

  Content({
    this.id = 0,
    this.title = '',
    this.description,
    this.coverImageUrl,
    this.contentTypeId = 0,
    this.contentTypeName,
    this.ageRatingId,
    this.ageRatingName,
    this.languageId,
    this.languageName,
    this.releaseYear,
    this.avgRating = 0,
    this.totalRatings = 0,
    this.isActive = true,
    DateTime? createdAt,
    List<String>? genres,
  })  : createdAt = createdAt ?? DateTime.now(),
        genres = genres ?? [];

  factory Content.fromJson(Map<String, dynamic> json) {
    return Content(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'],
      coverImageUrl: json['coverImageUrl'],
      contentTypeId: json['contentTypeId'] ?? 0,
      contentTypeName: json['contentTypeName'],
      ageRatingId: json['ageRatingId'],
      ageRatingName: json['ageRatingName'],
      languageId: json['languageId'],
      languageName: json['languageName'],
      releaseYear: json['releaseYear'],
      avgRating: (json['avgRating'] ?? 0).toDouble(),
      totalRatings: json['totalRatings'] ?? 0,
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      genres: json['genres'] != null
          ? List<String>.from(json['genres'])
          : [],
    );
  }
}