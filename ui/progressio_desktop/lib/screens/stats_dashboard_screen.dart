import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:progressio_desktop/layouts/master_screen.dart';
import 'package:progressio_desktop/model/admin_dashboard.dart';
import 'package:progressio_desktop/providers/admin_dashboard_provider.dart';
import 'package:progressio_desktop/utils/app_colors.dart';
import 'package:progressio_desktop/utils/utils.dart';

class StatsDashboardScreen extends StatefulWidget {
  const StatsDashboardScreen({super.key});

  @override
  State<StatsDashboardScreen> createState() => _StatsDashboardScreenState();
}

class _StatsDashboardScreenState extends State<StatsDashboardScreen> {
  late AdminDashboardProvider _dashboardProvider;
  AdminDashboard? _dashboard;
  bool _loading = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _dashboardProvider = context.read<AdminDashboardProvider>();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _dashboardProvider.getDashboard();
      setState(() => _dashboard = data);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MasterScreen(
      title: 'Stats Dashboard',
      child: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 48),
          const SizedBox(height: 12),
          Text(_error!,
              style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final d = _dashboard;
    if (d == null) return const SizedBox();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Overview', Icons.dashboard_rounded),
          const SizedBox(height: 12),
          _buildKpiRow(d),
          const SizedBox(height: 28),
          _buildSectionHeader('New Users by Month', Icons.person_add_rounded),
          const SizedBox(height: 12),
          _buildNewUsersChart(d.newUsers),
          const SizedBox(height: 28),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(
                        'Top 10 Content', Icons.leaderboard_rounded),
                    const SizedBox(height: 12),
                    _buildTopContentTable(d.topContent),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(
                        'Achievement Stats', Icons.emoji_events_rounded),
                    const SizedBox(height: 12),
                    _buildAchievementList(d.achievementStats.topAchievements),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          _buildSectionHeader(
              'Upcoming Releases (next 7 days)', Icons.upcoming_rounded),
          const SizedBox(height: 12),
          _buildUpcomingReleases(d.upcomingReleases),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildKpiRow(AdminDashboard d) {
    return Row(
      children: [
        Expanded(
          child: _KpiCard(
            label: 'Active Users (7d)',
            value: d.activeUsers.activeLast7Days.toString(),
            icon: Icons.people_rounded,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _KpiCard(
            label: 'Top Content Tracked',
            value: d.topContent.isNotEmpty
                ? d.topContent.first.followerCount.toString()
                : '0',
            icon: Icons.movie_rounded,
            color: AppColors.secondary,
            subtitle: d.topContent.isNotEmpty
                ? d.topContent.first.title
                : '',
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _KpiCard(
            label: 'Upcoming Releases',
            value: d.upcomingReleases.length.toString(),
            icon: Icons.calendar_today_rounded,
            color: AppColors.warning,
            subtitle: 'Next 7 days',
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _KpiCard(
            label: 'Top Achievement',
            value: d.achievementStats.topAchievements.isNotEmpty
                ? d.achievementStats.topAchievements.first.earnedCount
                    .toString()
                : '0',
            icon: Icons.emoji_events_rounded,
            color: AppColors.premium,
            subtitle: d.achievementStats.topAchievements.isNotEmpty
                ? d.achievementStats.topAchievements.first.name
                : '',
          ),
        ),
      ],
    );
  }

  Widget _buildNewUsersChart(NewUsersData newUsers) {
    final items = newUsers.byMonth;
    if (items.isEmpty) {
      return _emptyState('No user data available.');
    }

    final maxY = items
        .map((e) => e.count.toDouble())
        .fold(0.0, (a, b) => a > b ? a : b);

    return Container(
      height: 220,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY * 1.3 + 1,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => AppColors.surface,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final label = items[groupIndex].period;
                return BarTooltipItem(
                  '$label\n${rod.toY.toInt()} users',
                  const TextStyle(color: AppColors.textPrimary, fontSize: 12),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= items.length) {
                    return const SizedBox();
                  }
                  final period = items[idx].period;
                  final label = period.length > 7 ? period.substring(5) : period;
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(label,
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 11)),
                  );
                },
                reservedSize: 28,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (value, meta) {
                  if (value == 0) return const SizedBox();
                  return Text(value.toInt().toString(),
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 11));
                },
              ),
            ),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            getDrawingHorizontalLine: (_) => FlLine(
              color: AppColors.divider.withOpacity(0.4),
              strokeWidth: 1,
            ),
            drawVerticalLine: false,
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(items.length, (i) {
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: items[i].count.toDouble(),
                  color: AppColors.primary,
                  width: 18,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4)),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildTopContentTable(List<TopContentItem> items) {
    if (items.isEmpty) return _emptyState('No content data available.');

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor:
                const WidgetStatePropertyAll(AppColors.surface),
            dataRowColor:
                const WidgetStatePropertyAll(AppColors.card),
            columns: const [
              DataColumn(label: Text('#')),
              DataColumn(label: Text('Title')),
              DataColumn(label: Text('Type')),
              DataColumn(label: Text('Rating')),
              DataColumn(label: Text('Followers')),
            ],
            rows: List.generate(items.length, (i) {
              final item = items[i];
              return DataRow(cells: [
                DataCell(Text(
                  '${i + 1}',
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 13),
                )),
                DataCell(
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 220),
                    child: Text(
                      item.title,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
                DataCell(_typeChip(item.contentType)),
                DataCell(Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        color: AppColors.premium, size: 14),
                    const SizedBox(width: 4),
                    Text(item.avgRating.toStringAsFixed(1),
                        style:
                            const TextStyle(color: AppColors.premium)),
                  ],
                )),
                DataCell(Text(
                  item.followerCount.toString(),
                  style: const TextStyle(color: AppColors.textSecondary),
                )),
              ]);
            }),
          ),
        ),
      ),
    );
  }

  Widget _typeChip(String type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(type,
          style: const TextStyle(color: AppColors.primary, fontSize: 12)),
    );
  }

  Widget _buildAchievementList(List<AchievementEarnItem> items) {
    if (items.isEmpty) return _emptyState('No achievement data available.');

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, color: AppColors.divider),
        itemBuilder: (_, i) {
          final item = items[i];
          return Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.premium.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.emoji_events,
                      color: AppColors.premium, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name,
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500)),
                      Text(item.code,
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 11)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${item.earnedCount}x',
                    style: const TextStyle(
                        color: AppColors.success,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildUpcomingReleases(List<UpcomingReleaseItem> items) {
    if (items.isEmpty) {
      return _emptyState('No upcoming releases in the next 7 days.');
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor:
                const WidgetStatePropertyAll(AppColors.surface),
            dataRowColor:
                const WidgetStatePropertyAll(AppColors.card),
            columns: const [
              DataColumn(label: Text('Title')),
              DataColumn(label: Text('Content')),
              DataColumn(label: Text('Type')),
              DataColumn(label: Text('Release Date')),
              DataColumn(label: Text('Details')),
            ],
            rows: items.map((item) {
              return DataRow(cells: [
                DataCell(
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 200),
                    child: Text(item.title,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500)),
                  ),
                ),
                DataCell(
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 180),
                    child: Text(item.contentTitle,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppColors.textSecondary)),
                  ),
                ),
                DataCell(_itemTypeChip(item.itemType)),
                DataCell(Text(
                  formatDate(item.releaseDate),
                  style: const TextStyle(color: AppColors.warning),
                )),
                DataCell(Text(
                  _releaseDetails(item),
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 12),
                )),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }

  String _releaseDetails(UpcomingReleaseItem item) {
    if (item.seasonNumber != null && item.episodeNumber != null) {
      return 'S${item.seasonNumber} E${item.episodeNumber}';
    }
    if (item.chapterNumber != null) {
      return 'Ch. ${item.chapterNumber}';
    }
    return '-';
  }

  Widget _itemTypeChip(String type) {
    final isEpisode = type.toLowerCase() == 'episode';
    final color = isEpisode ? AppColors.secondary : AppColors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(type,
          style: TextStyle(color: color, fontSize: 12)),
    );
  }

  Widget _emptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Center(
        child: Text(message,
            style: const TextStyle(color: AppColors.textMuted)),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty)
                  Text(
                    subtitle!,
                    style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}