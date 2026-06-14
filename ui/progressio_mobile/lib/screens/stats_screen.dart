import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:progressio_mobile/model/stats.dart';
import 'package:progressio_mobile/providers/auth_provider.dart';
import 'package:progressio_mobile/providers/stats_provider.dart';
import 'package:progressio_mobile/utils/app_colors.dart';
import 'package:progressio_mobile/widgets/app_ui.dart';
import 'package:progressio_mobile/widgets/skeleton_loader.dart';
import 'package:progressio_mobile/screens/wrapped_screen.dart';
import 'package:progressio_mobile/screens/premium_screen.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  BasicStats? _basic;
  PremiumStats? _premium;
  bool _loadingBasic = true;
  bool _loadingPremium = false;
  bool _isPremium = false;
  String? _premiumError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final basic = await context.read<StatsProvider>().getBasicStats();
      if (mounted) setState(() {
        _basic = basic;
        _loadingBasic = false;
        _isPremium = AuthProvider.isPremium;
      });
      if (_isPremium) _loadPremium();
    } catch (_) {
      if (mounted) setState(() => _loadingBasic = false);
    }
  }

  Future<void> _loadPremium() async {
    setState(() => _loadingPremium = true);
    try {
      final p = await context.read<StatsProvider>().getPremiumStats();
      if (mounted) setState(() {
        _premium = p;
        _loadingPremium = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _premiumError = e.toString();
        _loadingPremium = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppShellBackground(
        child: SafeArea(
          child: _loadingBasic
              ? _buildSkeleton()
              : RefreshIndicator(
                  color: AppColors.primary,
                  backgroundColor: AppColors.card,
                  onRefresh: _load,
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(child: _buildHeader()),
                      SliverToBoxAdapter(child: _buildBasicKpis()),
                      SliverToBoxAdapter(child: _buildStreakRow()),
                      if (_isPremium) ...[
                        if (_loadingPremium)
                          const SliverToBoxAdapter(child: _PremiumSkeleton())
                        else if (_premium != null) ...[
                          SliverToBoxAdapter(child: _buildHoursRow()),
                          SliverToBoxAdapter(child: _buildGenreChart()),
                          SliverToBoxAdapter(child: _buildHeatmap()),
                          SliverToBoxAdapter(child: _buildWrappedBanner()),
                        ],
                      ] else
                        SliverToBoxAdapter(child: _buildPremiumLock()),
                      const SliverToBoxAdapter(child: SizedBox(height: 32)),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 4),
      child: Row(
        children: [
          const Text(
            'My Stats',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          if (_isPremium)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.premium, AppColors.primary]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'PREMIUM',
                style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.w800),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBasicKpis() {
    final b = _basic!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
      child: Row(
        children: [
          Expanded(child: _kpiCard('Completed', b.totalCompleted.toString(), Icons.check_circle_rounded, AppColors.success)),
          const SizedBox(width: 10),
          Expanded(child: _kpiCard('In Progress', b.totalInProgress.toString(), Icons.play_circle_rounded, AppColors.primary)),
          const SizedBox(width: 10),
          Expanded(child: _kpiCard('On Hold', b.totalOnHold.toString(), Icons.pause_circle_rounded, AppColors.warning)),
        ],
      ),
    );
  }

  Widget _kpiCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(color: AppColors.textFaint, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildStreakRow() {
    final b = _basic!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
      child: Row(
        children: [
          Expanded(
            child: _streakCard(
              '🔥',
              '${b.currentStreak}',
              'Day streak',
              AppColors.warning,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _streakCard(
              '🏆',
              '${b.longestStreak}',
              'Best streak',
              AppColors.premium,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _streakCard(
              '🚫',
              _basic!.totalCancelled.toString(),
              'Cancelled',
              AppColors.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _streakCard(String emoji, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(color: AppColors.textFaint, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildHoursRow() {
    final p = _premium!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Time Invested',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _hoursCard('Watch', p.totalWatchHours, Icons.tv_rounded, AppColors.info)),
              const SizedBox(width: 10),
              Expanded(child: _hoursCard('Read', p.totalReadHours, Icons.menu_book_rounded, AppColors.success)),
              const SizedBox(width: 10),
              Expanded(child: _hoursCard('Game', p.totalGameHours, Icons.sports_esports_rounded, AppColors.primary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _hoursCard(String label, double hours, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text('${hours.toStringAsFixed(0)}h',
              style: TextStyle(
                  color: color, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(color: AppColors.textFaint, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildGenreChart() {
    final genres = _premium!.topGenres;
    if (genres.isEmpty) return const SizedBox.shrink();

    final sections = genres.asMap().entries.map((e) {
      final colors = [
        AppColors.primary,
        AppColors.info,
        AppColors.success,
        AppColors.warning,
        AppColors.premium,
      ];
      final color = colors[e.key % colors.length];
      return PieChartSectionData(
        value: e.value.completedCount.toDouble(),
        title: e.value.genreName.length > 8
            ? '${e.value.genreName.substring(0, 7)}…'
            : e.value.genreName,
        color: color,
        radius: 62,
        titleStyle: const TextStyle(
            color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
      );
    }).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Top Genres',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: PieChart(PieChartData(
                sections: sections,
                centerSpaceRadius: 40,
                sectionsSpace: 2,
              )),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 6,
              children: genres.asMap().entries.map((e) {
                final colors = [
                  AppColors.primary,
                  AppColors.info,
                  AppColors.success,
                  AppColors.warning,
                  AppColors.premium,
                ];
                final color = colors[e.key % colors.length];
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 10, height: 10,
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                    const SizedBox(width: 5),
                    Text(e.value.genreName,
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    const SizedBox(width: 4),
                    Text('${e.value.completedCount}',
                        style: const TextStyle(color: AppColors.textFaint, fontSize: 11)),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeatmap() {
    final entries = _premium!.heatmap;
    if (entries.isEmpty) return const SizedBox.shrink();

    final maxCount = entries.fold(0, (m, e) => e.count > m ? e.count : m);

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Activity Heatmap',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            Wrap(
              spacing: 3,
              runSpacing: 3,
              children: entries.map((e) {
                final intensity = maxCount == 0 ? 0.0 : e.count / maxCount;
                return Tooltip(
                  message: '${e.date.toLocal().toString().substring(0, 10)}: ${e.count}',
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: e.count == 0
                          ? AppColors.surface
                          : AppColors.primary.withOpacity(0.2 + 0.8 * intensity),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumLock() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 0),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_rounded, color: AppColors.primary, size: 28),
            ),
            const SizedBox(height: 14),
            const Text(
              'Premium Stats',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Upgrade to Premium to unlock detailed stats: watch hours, genre breakdown, activity heatmap, and yearly Wrapped.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final result = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(builder: (_) => const PremiumScreen()),
                  );
                  if (result == true && mounted) {
                    setState(() {
                      _isPremium = AuthProvider.isPremium;
                      _loadingBasic = true;
                    });
                    _load();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Upgrade to Premium',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWrappedBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const WrappedScreen()),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primary.withOpacity(0.35)),
          ),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome_rounded,
                  color: AppColors.primary, size: 24),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Year in Review',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'See your personal Wrapped for this year',
                      style: TextStyle(
                          color: AppColors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textFaint, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(18),
      child: Column(
        children: [
          SkeletonBox(width: 160, height: 28, radius: 8),
          SizedBox(height: 20),
          Row(children: [
            Expanded(child: SkeletonBox(width: double.infinity, height: 80)),
            SizedBox(width: 10),
            Expanded(child: SkeletonBox(width: double.infinity, height: 80)),
            SizedBox(width: 10),
            Expanded(child: SkeletonBox(width: double.infinity, height: 80)),
          ]),
          SizedBox(height: 14),
          Row(children: [
            Expanded(child: SkeletonBox(width: double.infinity, height: 72)),
            SizedBox(width: 10),
            Expanded(child: SkeletonBox(width: double.infinity, height: 72)),
            SizedBox(width: 10),
            Expanded(child: SkeletonBox(width: double.infinity, height: 72)),
          ]),
        ],
      ),
    );
  }
}

class _PremiumSkeleton extends StatelessWidget {
  const _PremiumSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(18, 20, 18, 0),
      child: Column(
        children: [
          SkeletonBox(width: double.infinity, height: 100),
          SizedBox(height: 14),
          SkeletonBox(width: double.infinity, height: 200),
        ],
      ),
    );
  }
}