import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:progressio_desktop/core/api_client.dart';

class ReportProvider with ChangeNotifier {
  Future<Uint8List> downloadContentPopularityReport() =>
      _downloadPdf('admin/reports/content-popularity');

  Future<Uint8List> downloadUserActivityReport() =>
      _downloadPdf('admin/reports/user-activity');

  Future<Uint8List> downloadUpcomingReleasesReport() =>
      _downloadPdf('admin/reports/upcoming-releases');

  Future<Uint8List> _downloadPdf(String path) async {
    final response = await ApiClient.get(path);
    return response.bodyBytes;
  }
}