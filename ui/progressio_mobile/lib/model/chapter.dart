class Chapter {
  final int id;
  final int contentId;
  final String? contentTitle;
  final int chapterNumber;
  final String title;
  final int? pageCount;
  final DateTime? releaseDate;

  Chapter({
    this.id = 0,
    this.contentId = 0,
    this.contentTitle,
    this.chapterNumber = 1,
    this.title = '',
    this.pageCount,
    this.releaseDate,
  });

  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
      id: json['id'] ?? 0,
      contentId: json['contentId'] ?? 0,
      contentTitle: json['contentTitle'],
      chapterNumber: json['chapterNumber'] ?? 1,
      title: json['title'] ?? '',
      pageCount: json['pageCount'],
      releaseDate: json['releaseDate'] != null
          ? DateTime.parse(json['releaseDate'])
          : null,
    );
  }
}