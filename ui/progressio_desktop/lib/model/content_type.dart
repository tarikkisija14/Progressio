class ContentType {
  final int id;
  final String name;

  ContentType({this.id = 0, this.name = ''});

  factory ContentType.fromJson(Map<String, dynamic> json) {
    return ContentType(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }
}