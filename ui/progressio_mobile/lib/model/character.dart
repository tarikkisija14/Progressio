

class Character {
  final int id;
  final int contentId;
  final String? contentTitle;
  final String name;
  final String? description;
  final String? imageUrl;
  final bool isMainCharacter;

  Character({
    this.id = 0,
    this.contentId = 0,
    this.contentTitle,
    this.name = '',
    this.description,
    this.imageUrl,
    this.isMainCharacter = false,
  });

  factory Character.fromJson(Map<String, dynamic> json) {
    return Character(
      id: json['id'] ?? 0,
      contentId: json['contentId'] ?? 0,
      contentTitle: json['contentTitle'],
      name: json['name'] ?? '',
      description: json['description'],
      imageUrl: json['imageUrl'],
      isMainCharacter: json['isMainCharacter'] ?? false,
    );
  }
}