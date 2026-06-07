class AgeRating {
  final int id;
  final String name;

  AgeRating({this.id = 0, this.name = ''});

  factory AgeRating.fromJson(Map<String, dynamic> json) {
    return AgeRating(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }
}