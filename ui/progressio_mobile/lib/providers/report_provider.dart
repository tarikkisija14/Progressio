import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:progressio_mobile/providers/auth_provider.dart';

class ReportProvider with ChangeNotifier {
  static const String _baseUrl = String.fromEnvironment(
    'baseUrl',
    defaultValue: 'https://localhost:7204/api/',
  );

  Map<String, String> _headers() => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AuthProvider.token}',
      };

  Future<Uint8List> downloadContentPopularityReport() async {
    return _downloadPdf('admin/reports/content-popularity');
  }

  Future<Uint8List> downloadUserActivityReport() async {
    return _downloadPdf('admin/reports/user-activity');
  }

  Future<Uint8List> downloadUpcomingReleasesReport() async {
    return _downloadPdf('admin/reports/upcoming-releases');
  }

  Future<Uint8List> _downloadPdf(String path) async {
    final url = '$_baseUrl$path';
    final response = await http.get(Uri.parse(url), headers: _headers());

    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized');
    } else {
      throw Exception('Failed to generate report (${response.statusCode})');
    }
  }
}