class Language {
  final int id;
  final String name;
  final String code;

  const Language({
    this.id = 0,
    this.name = '',
    this.code = '',
  });

  factory Language.fromJson(Map<String, dynamic> json) {
    return Language(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
    );
  }
}