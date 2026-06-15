import 'package:flutter/material.dart';
import 'package:progressio_mobile/core/api_client.dart';
import 'package:progressio_mobile/model/admin_dashboard.dart';

class AdminDashboardProvider with ChangeNotifier {
  Future<AdminDashboard> getDashboard() async {
    final response = await ApiClient.get('admin/dashboard');
    return AdminDashboard.fromJson(
      ApiClient.decode(response) as Map<String, dynamic>,
    );
  }
}
