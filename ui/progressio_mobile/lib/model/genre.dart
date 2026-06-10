class Genre {
  final int id;
  final String name;

  Genre({this.id = 0, this.name = ''});

  factory Genre.fromJson(Map<String, dynamic> json) {
    return Genre(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }
}