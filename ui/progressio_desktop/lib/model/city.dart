class City {
  final int id;
  final String name;
  final int countryId;
  final String? countryName;

  City({this.id = 0, this.name = '', this.countryId = 0, this.countryName});

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      countryId: json['countryId'] ?? 0,
      countryName: json['countryName'],
    );
  }
}