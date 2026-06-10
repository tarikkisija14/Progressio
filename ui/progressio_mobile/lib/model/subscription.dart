class Subscription {
  final int id;
  final int userId;
  final String username;
  final String userFullName;
  final String userEmail;
  final String planType;
  final String status;
  final DateTime startDate;
  final DateTime endDate;
  final bool autoRenew;
  final bool isPremium;
  final String? stripePaymentIntentId;

  Subscription({
    this.id = 0,
    this.userId = 0,
    this.username = '',
    this.userFullName = '',
    this.userEmail = '',
    this.planType = '',
    this.status = '',
    DateTime? startDate,
    DateTime? endDate,
    this.autoRenew = false,
    this.isPremium = false,
    this.stripePaymentIntentId,
  })  : startDate = startDate ?? DateTime.now(),
        endDate = endDate ?? DateTime.now();

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? 0,
      username: json['username'] ?? '',
      userFullName: json['userFullName'] ?? '',
      userEmail: json['userEmail'] ?? '',
      planType: json['planType'] ?? '',
      status: json['status'] ?? '',
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'])
          : DateTime.now(),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'])
          : DateTime.now(),
      autoRenew: json['autoRenew'] ?? false,
      isPremium: json['isPremium'] ?? false,
      stripePaymentIntentId: json['stripePaymentIntentId'],
    );
  }
}