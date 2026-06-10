// lib/model/user_list.dart
// Usklađeno s UserListResponse iz backenda:
//   Id, UserId, OwnerUsername, Name, Description,
//   IsPublic, IsShared, ItemCount, MemberCount, CreatedAt

class UserList {
  final int id;
  final int userId;
  final String ownerUsername;   // OwnerUsername na backendu
  final String name;
  final String? description;
  final bool isPublic;
  final bool isShared;
  final int itemCount;
  final int memberCount;
  final DateTime createdAt;

  UserList({
    this.id = 0,
    this.userId = 0,
    this.ownerUsername = '',
    this.name = '',
    this.description,
    this.isPublic = false,
    this.isShared = false,
    this.itemCount = 0,
    this.memberCount = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory UserList.fromJson(Map<String, dynamic> json) {
    return UserList(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? 0,
      ownerUsername: json['ownerUsername'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      isPublic: json['isPublic'] ?? false,
      isShared: json['isShared'] ?? false,
      itemCount: json['itemCount'] ?? 0,
      memberCount: json['memberCount'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}

// ── UserListItemResponse ─────────────────────────────────────────────────────

class UserListItem {
  final int id;
  final int contentId;
  final String contentTitle;
  final String? contentCoverImageUrl;
  final String contentTypeName;
  final int priority;
  final String? note;
  final DateTime addedAt;

  UserListItem({
    this.id = 0,
    this.contentId = 0,
    this.contentTitle = '',
    this.contentCoverImageUrl,
    this.contentTypeName = '',
    this.priority = 0,
    this.note,
    DateTime? addedAt,
  }) : addedAt = addedAt ?? DateTime.now();

  factory UserListItem.fromJson(Map<String, dynamic> json) {
    return UserListItem(
      id: json['id'] ?? 0,
      contentId: json['contentId'] ?? 0,
      contentTitle: json['contentTitle'] ?? '',
      contentCoverImageUrl: json['contentCoverImageUrl'],
      contentTypeName: json['contentTypeName'] ?? '',
      priority: json['priority'] ?? 0,
      note: json['note'],
      addedAt: json['addedAt'] != null
          ? DateTime.parse(json['addedAt'])
          : DateTime.now(),
    );
  }
}

// ── UserListMemberResponse ───────────────────────────────────────────────────

class UserListMember {
  final int userId;
  final String username;
  final String? profileImageUrl;
  final bool canEdit;
  final DateTime joinedAt;

  UserListMember({
    this.userId = 0,
    this.username = '',
    this.profileImageUrl,
    this.canEdit = false,
    DateTime? joinedAt,
  }) : joinedAt = joinedAt ?? DateTime.now();

  factory UserListMember.fromJson(Map<String, dynamic> json) {
    return UserListMember(
      userId: json['userId'] ?? 0,
      username: json['username'] ?? '',
      profileImageUrl: json['profileImageUrl'],
      canEdit: json['canEdit'] ?? false,
      joinedAt: json['joinedAt'] != null
          ? DateTime.parse(json['joinedAt'])
          : DateTime.now(),
    );
  }
}