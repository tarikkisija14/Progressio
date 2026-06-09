import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:progressio_desktop/layouts/master_screen.dart';
import 'package:progressio_desktop/providers/report_provider.dart';
import 'package:progressio_desktop/utils/app_colors.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  late ReportProvider _reportProvider;

  final Map<String, bool> _loading = {
    'content-popularity': false,
    'user-activity': false,
    'upcoming-releases': false,
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reportProvider = context.read<ReportProvider>();
  }

  Future<void> _download(String key, String fileName) async {
    setState(() => _loading[key] = true);
    try {
      late Uint8List bytes;
      switch (key) {
        case 'content-popularity':
          bytes = await _reportProvider.downloadContentPopularityReport();
          break;
        case 'user-activity':
          bytes = await _reportProvider.downloadUserActivityReport();
          break;
        case 'upcoming-releases':
          bytes = await _reportProvider.downloadUpcomingReleasesReport();
          break;
        default:
          throw Exception('Unknown report key');
      }
      await _saveFile(bytes, fileName);
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _loading[key] = false);
    }
  }

  Future<void> _saveFile(Uint8List bytes, String fileName) async {
    try {
      final String dir = _getDownloadsPath();
      final file = File('$dir/$fileName');
      await file.writeAsBytes(bytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved: ${file.path}'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Open',
              textColor: Colors.white,
              onPressed: () => _openFile(file.path),
            ),
          ),
        );
      }
    } catch (e) {
      _showError('Could not save file: $e');
    }
  }

  String _getDownloadsPath() {
    if (Platform.isWindows) {
      final home = Platform.environment['USERPROFILE'] ?? 'C:\\Users\\Public';
      return '$home\\Downloads';
    } else if (Platform.isMacOS) {
      final home = Platform.environment['HOME'] ?? '/tmp';
      return '$home/Downloads';
    }
    return '/tmp';
  }

  void _openFile(String path) {
    try {
      if (Platform.isWindows) {
        Process.run('cmd', ['/c', 'start', '', path]);
      } else if (Platform.isMacOS) {
        Process.run('open', [path]);
      } else {
        Process.run('xdg-open', [path]);
      }
    } catch (_) {}
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MasterScreen(
      title: 'Reports',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _ReportCard(
                    icon: Icons.bar_chart_rounded,
                    iconColor: AppColors.primary,
                    title: 'Content Popularity',
                    description:
                        'Top content sorted by number of followers. '
                        'Includes title, type, average rating, total ratings and genres.',
                    isLoading: _loading['content-popularity'] ?? false,
                    onDownload: () =>
                        _download('content-popularity', 'content-popularity-report.pdf'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _ReportCard(
                    icon: Icons.people_alt_rounded,
                    iconColor: AppColors.secondary,
                    title: 'User Activity',
                    description:
                        'Active users, completions and subscriptions by period. '
                        'Shows trends in user engagement over time.',
                    isLoading: _loading['user-activity'] ?? false,
                    onDownload: () =>
                        _download('user-activity', 'user-activity-report.pdf'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _ReportCard(
                    icon: Icons.calendar_month_rounded,
                    iconColor: AppColors.warning,
                    title: 'Upcoming Releases',
                    description:
                        'Episodes and chapters releasing in the next 30 days. '
                        'Useful for scheduling announcements and notifications.',
                    isLoading: _loading['upcoming-releases'] ?? false,
                    onDownload: () =>
                        _download('upcoming-releases', 'upcoming-releases-report.pdf'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            _buildInfoBox(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'PDF Reports',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Generate and download admin reports as PDF files.',
          style: TextStyle(color: AppColors.textMuted, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildInfoBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.primary, size: 18),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Reports are generated in real-time from the current database state. '
              'Files are saved to your Downloads folder and opened automatically.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final bool isLoading;
  final VoidCallback onDownload;

  const _ReportCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.isLoading,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            description,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 20),
          const Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : onDownload,
                  icon: isLoading
                      ? const SizedBox(
                          width: 15,
                          height: 15,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.download_rounded, size: 16),
                  label: Text(isLoading ? 'Generating...' : 'Download PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: isLoading ? null : onDownload,
                icon: const Icon(Icons.print_rounded, size: 16),
                label: const Text('Print'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: AppColors.divider),
                  padding: const EdgeInsets.symmetric(
                      vertical: 11, horizontal: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}