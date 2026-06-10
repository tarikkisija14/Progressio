

class Recommendation {
  final int contentId;
  final String title;
  final String? coverImageUrl;
  final String? contentTypeName;
  final double avgRating;
  final int totalRatings;
  final int? releaseYear;
  final double score;
  final String explanationText;

  Recommendation({
    this.contentId = 0,
    this.title = '',
    this.coverImageUrl,
    this.contentTypeName,
    this.avgRating = 0,
    this.totalRatings = 0,
    this.releaseYear,
    this.score = 0,
    this.explanationText = '',
  });

  factory Recommendation.fromJson(Map<String, dynamic> json) {
    return Recommendation(
      contentId: json['contentId'] ?? 0,
      title: json['title'] ?? '',
      coverImageUrl: json['coverImageUrl'],
      contentTypeName: json['contentTypeName'],
      avgRating: (json['avgRating'] ?? 0).toDouble(),
      totalRatings: json['totalRatings'] ?? 0,
      releaseYear: json['releaseYear'],
      score: (json['score'] ?? 0).toDouble(),
      explanationText: json['explanationText'] ?? '',
    );
  }
}