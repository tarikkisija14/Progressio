class Achievement {
  final int id;
  final String code;
  final String name;
  final String? description;
  final String? iconUrl;
  final String? conditionJson;

  Achievement({
    this.id = 0,
    this.code = '',
    this.name = '',
    this.description,
    this.iconUrl,
    this.conditionJson,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] ?? 0,
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      iconUrl: json['iconUrl'],
      conditionJson: json['conditionJson'],
    );
  }
}