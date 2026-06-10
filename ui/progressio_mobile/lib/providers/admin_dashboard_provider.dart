import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:progressio_mobile/model/admin_dashboard.dart';
import 'package:progressio_mobile/providers/auth_provider.dart';

class AdminDashboardProvider with ChangeNotifier {
  static const String _baseUrl = String.fromEnvironment(
    'baseUrl',
    defaultValue: 'https://localhost:7204/api/',
  );

  Map<String, String> _headers() => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AuthProvider.token}',
      };

  Future<AdminDashboard> getDashboard() async {
    final url = '${_baseUrl}admin/dashboard';
    final response = await http.get(Uri.parse(url), headers: _headers());

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return AdminDashboard.fromJson(data);
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized');
    } else {
      throw Exception('Failed to load dashboard (${response.statusCode})');
    }
  }
}