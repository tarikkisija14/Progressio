class Subscription {
  final int id;
  final String planType;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final bool autoRenew;
  final bool isPremium;

  Subscription({
    this.id = 0,
    this.planType = '',
    DateTime? startDate,
    DateTime? endDate,
    this.status = '',
    this.autoRenew = false,
    this.isPremium = false,
  })  : startDate = startDate ?? DateTime.now(),
        endDate = endDate ?? DateTime.now();

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'] ?? 0,
      planType: json['planType'] ?? '',
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'])
          : DateTime.now(),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'])
          : DateTime.now(),
      status: json['status'] ?? '',
      autoRenew: json['autoRenew'] ?? false,
      isPremium: json['isPremium'] ?? false,
    );
  }
}