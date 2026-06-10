class UserList {
  final int id;
  final int userId;
  final String creatorUsername;
  final String name;
  final String? description;
  final bool isPublic;
  final bool isShared;
  final int itemCount;
  final DateTime createdAt;

  UserList({
    this.id = 0,
    this.userId = 0,
    this.creatorUsername = '',
    this.name = '',
    this.description,
    this.isPublic = false,
    this.isShared = false,
    this.itemCount = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory UserList.fromJson(Map<String, dynamic> json) {
    return UserList(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? 0,
      creatorUsername: json['creatorUsername'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      isPublic: json['isPublic'] ?? false,
      isShared: json['isShared'] ?? false,
      itemCount: json['itemCount'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}