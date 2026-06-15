class AgeRating {
  final int id;
  final String name;
  final int minAge;

  const AgeRating({
    this.id = 0,
    this.name = '',
    this.minAge = 0,
  });

  factory AgeRating.fromJson(Map<String, dynamic> json) {
    return AgeRating(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      minAge: json['minAge'] as int? ?? 0,
    );
  }
}
