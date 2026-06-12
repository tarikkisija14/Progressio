import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:progressio_mobile/providers/achievement_provider.dart';
import 'package:progressio_mobile/utils/app_colors.dart';
import 'package:progressio_mobile/widgets/app_ui.dart';
import 'package:progressio_mobile/widgets/skeleton_loader.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  List<dynamic> _achievements = [];
  bool _loading = true;
  int _page = 1;
  bool _hasMore = false;
  bool _loadingMore = false;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _load();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_loadingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _page = 1;
      _achievements = [];
    });
    try {
      final data = await context
          .read<AchievementProvider>()
          .getRaw('achievements/my', query: {'page': 1, 'pageSize': 30});
      if (mounted) {
        final list =
            data is Map ? (data['items'] as List? ?? []) : (data as List? ?? []);
        final total =
            data is Map ? (data['totalCount'] as int? ?? 0) : list.length;
        setState(() {
          _achievements = list;
          _hasMore = list.length < total;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Achievements load error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    setState(() => _loadingMore = true);
    final nextPage = _page + 1;
    try {
      final data = await context
          .read<AchievementProvider>()
          .getRaw('achievements/my',
              query: {'page': nextPage, 'pageSize': 30});
      if (mounted) {
        final list =
            data is Map ? (data['items'] as List? ?? []) : (data as List? ?? []);
        final total =
            data is Map ? (data['totalCount'] as int? ?? 0) : 0;
        setState(() {
          _achievements.addAll(list);
          _page = nextPage;
          _hasMore = _achievements.length < total;
          _loadingMore = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        title: const Text(
          'Achievements',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: AppShellBackground(
        child: RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.card,
          onRefresh: _load,
          child: _loading
              ? _buildSkeleton()
              : _achievements.isEmpty
                  ? _buildEmpty()
                  : GridView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.85,
                      ),
                      itemCount:
                          _achievements.length + (_loadingMore ? 3 : 0),
                      itemBuilder: (_, i) {
                        if (i >= _achievements.length) {
                          return const SkeletonBox(
                              width: double.infinity,
                              height: double.infinity,
                              radius: 14);
                        }
                        final a = _achievements[i];
                        return _AchievementCard(
                          name: a['achievementName'] ?? '',
                          iconUrl: a['achievementIconUrl'],
                          description: a['achievementDescription'],
                          earnedAt: a['earnedAt'] != null
                              ? DateTime.parse(a['earnedAt'])
                              : null,
                        );
                      },
                    ),
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: 9,
      itemBuilder: (_, __) => const SkeletonBox(
          width: double.infinity, height: double.infinity, radius: 14),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emoji_events_outlined,
                color: AppColors.textFaint, size: 52),
            SizedBox(height: 14),
            Text(
              'No achievements yet.\nKeep tracking to earn them!',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.textMuted, fontSize: 15, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final String name;
  final String? iconUrl;
  final String? description;
  final DateTime? earnedAt;

  const _AchievementCard({
    required this.name,
    this.iconUrl,
    this.description,
    this.earnedAt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          iconUrl != null && iconUrl!.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: iconUrl!,
                  width: 40,
                  height: 40,
                  fit: BoxFit.contain,
                  placeholder: (_, __) => const Icon(
                      Icons.emoji_events_rounded,
                      color: AppColors.premium,
                      size: 40),
                  errorWidget: (_, __, ___) => const Icon(
                      Icons.emoji_events_rounded,
                      color: AppColors.premium,
                      size: 40),
                )
              : const Icon(Icons.emoji_events_rounded,
                  color: AppColors.premium, size: 40),
          const SizedBox(height: 7),
          Text(
            name,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
          if (earnedAt != null) ...[
            const SizedBox(height: 4),
            Text(
              '${earnedAt!.day}/${earnedAt!.month}/${earnedAt!.year}',
              style: const TextStyle(
                  color: AppColors.textFaint, fontSize: 9),
            ),
          ],
        ],
      ),
    );
  }
}