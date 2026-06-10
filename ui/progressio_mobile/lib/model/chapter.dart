class Chapter {
  final int id;
  final int contentId;
  final String? contentTitle;
  final int chapterNumber;
  final String? title;
  final DateTime? publishedAt;
  final bool isAvailable;

  Chapter({
    this.id = 0,
    this.contentId = 0,
    this.contentTitle,
    this.chapterNumber = 1,
    this.title,
    this.publishedAt,
    this.isAvailable = true,
  });

  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
      id: json['id'] ?? 0,
      contentId: json['contentId'] ?? 0,
      contentTitle: json['contentTitle'],
      chapterNumber: json['chapterNumber'] ?? 1,
      title: json['title'],
      publishedAt: json['publishedAt'] != null
          ? DateTime.parse(json['publishedAt'])
          : null,
      isAvailable: json['isAvailable'] ?? true,
    );
  }
}