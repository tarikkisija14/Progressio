class NotificationItem {
  final int id;
  final String type;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;
  final int? relatedEntityId;

  NotificationItem({
    this.id = 0,
    this.type = '',
    this.title = '',
    this.message = '',
    this.isRead = false,
    DateTime? createdAt,
    this.relatedEntityId,
  }) : createdAt = createdAt ?? DateTime.now();

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] ?? 0,
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      isRead: json['isRead'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      relatedEntityId: json['relatedEntityId'],
    );
  }
}