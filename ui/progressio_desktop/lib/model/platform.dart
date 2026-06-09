class Platform {
  final int id;
  final String name;

  Platform({
    this.id = 0,
    this.name = '',
  });

  factory Platform.fromJson(Map<String, dynamic> json) {
    return Platform(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }
}