class Country {
  final int id;
  final String name;
  final String? code;

  Country({this.id = 0, this.name = '', this.code});

  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      code: json['code'],
    );
  }
}