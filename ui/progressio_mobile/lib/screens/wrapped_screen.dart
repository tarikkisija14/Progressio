import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:progressio_mobile/model/stats.dart';
import 'package:progressio_mobile/providers/stats_provider.dart';
import 'package:progressio_mobile/utils/app_colors.dart';
import 'package:progressio_mobile/widgets/app_ui.dart';
import 'package:progressio_mobile/widgets/skeleton_loader.dart';
import 'package:progressio_mobile/model/wrapped_stats.dart';

class WrappedScreen extends StatefulWidget {
  const WrappedScreen({super.key});

  @override
  State<WrappedScreen> createState() => _WrappedScreenState();
}

class _WrappedScreenState extends State<WrappedScreen> {
  WrappedStats? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await context.read<StatsProvider>().getWrapped();
      if (mounted) setState(() => _data = result);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        title: Text(
          _data != null ? '${_data!.year} in Review' : 'Year in Review',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: AppShellBackground(
        child: _loading
            ? _buildSkeleton()
            : _error != null
                ? _buildError()
                : _data == null
                    ? _buildEmpty()
                    : _buildContent(_data!),
      ),
    );
  }

  Widget _buildContent(WrappedStats d) {
    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.card,
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.auto_awesome_rounded,
                      color: AppColors.primary, size: 40),
                  const SizedBox(height: 12),
                  Text(
                    '${d.year}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 48,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Your year in review',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Stats grid
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.check_circle_rounded,
                    iconColor: AppColors.success,
                    label: 'Completed',
                    value: '${d.totalCompleted}',
                    subtitle: 'titles',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.schedule_rounded,
                    iconColor: AppColors.info,
                    label: 'Time spent',
                    value: _formatHours(d.totalHours),
                    subtitle: d.totalHours >= 1 ? 'hours' : 'hour',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            const _SectionLabel(text: 'Highlights'),
            const SizedBox(height: 12),

            if (d.topGenre != null)
              _HighlightTile(
                icon: Icons.label_rounded,
                color: AppColors.secondary,
                label: 'Top genre',
                value: d.topGenre!,
              ),

            if (d.bestRatedContent != null)
              _HighlightTile(
                icon: Icons.star_rounded,
                color: AppColors.premium,
                label: 'Best rated',
                value: d.bestRatedContent!,
              ),

            if (d.favoriteCharacter != null)
              _HighlightTile(
                icon: Icons.person_rounded,
                color: AppColors.primary,
                label: 'Favourite character',
                value: d.favoriteCharacter!,
              ),

            if (d.mostProductiveMonth != null)
              _HighlightTile(
                icon: Icons.calendar_month_rounded,
                color: AppColors.info,
                label: 'Most active month',
                value: d.mostProductiveMonth!,
              ),

            if (d.topGenre == null &&
                d.bestRatedContent == null &&
                d.favoriteCharacter == null &&
                d.mostProductiveMonth == null)
              _buildNoHighlights(),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildNoHighlights() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppDecorations.panel(),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded,
              color: AppColors.textFaint, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Complete more content this year to unlock highlights.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          SkeletonBox(width: double.infinity, height: 160, radius: 20),
          SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: SkeletonBox(width: double.infinity, height: 90)),
              SizedBox(width: 12),
              Expanded(child: SkeletonBox(width: double.infinity, height: 90)),
            ],
          ),
          SizedBox(height: 20),
          SkeletonBox(width: 120, height: 16),
          SizedBox(height: 12),
          SkeletonBox(width: double.infinity, height: 60, radius: 12),
          SizedBox(height: 10),
          SkeletonBox(width: double.infinity, height: 60, radius: 12),
          SizedBox(height: 10),
          SkeletonBox(width: double.infinity, height: 60, radius: 12),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppColors.error, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Could not load your Year in Review.',
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: AppColors.textMuted, fontSize: 15),
            ),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded,
                  color: AppColors.primary),
              label: const Text('Try again',
                  style: TextStyle(color: AppColors.primary)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wrap_text_rounded,
                color: AppColors.textFaint, size: 52),
            SizedBox(height: 16),
            Text(
              'No data yet for this year.\nKeep tracking to see your highlights!',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.textMuted, fontSize: 15, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  String _formatHours(double h) {
    if (h >= 1000) return '${(h / 1000).toStringAsFixed(1)}k';
    if (h >= 10) return h.toStringAsFixed(0);
    return h.toStringAsFixed(1);
  }
}

// ── WIDGETS ──────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String subtitle;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.panel(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
                color: AppColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _HighlightTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _HighlightTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: AppDecorations.panel(),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                      color: AppColors.textFaint, fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
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

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
      ),
    );
  }
}