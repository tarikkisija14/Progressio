class Language {
  final int id;
  final String name;

  Language({this.id = 0, this.name = ''});

  factory Language.fromJson(Map<String, dynamic> json) {
    return Language(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }
}