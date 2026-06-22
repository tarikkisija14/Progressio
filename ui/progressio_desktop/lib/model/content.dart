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
  final List<int> genreIds;
  final List<ContentPlatform> platforms;

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
    List<int>? genreIds,
    List<ContentPlatform>? platforms,
  })  : createdAt = createdAt ?? DateTime.now(),
        genres = genres ?? [],
        genreIds = genreIds ?? [],
        platforms = platforms ?? [];

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
      genreIds: json['genreIds'] != null
          ? List<int>.from(json['genreIds'])
          : [],
      platforms: json['platforms'] != null
          ? (json['platforms'] as List)
              .map((p) => ContentPlatform.fromJson(p as Map<String, dynamic>))
              .toList()
          : [],
    );
  }
}

class ContentPlatform {
  final int id;
  final String name;

  ContentPlatform({required this.id, required this.name});

  factory ContentPlatform.fromJson(Map<String, dynamic> json) =>
      ContentPlatform(id: json['id'] ?? 0, name: json['name'] ?? '');
}