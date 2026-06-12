import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:progressio_mobile/screens/calendar_screen.dart';

import 'package:progressio_mobile/model/calendar_item.dart';
import 'package:progressio_mobile/model/content.dart';
import 'package:progressio_mobile/model/recommendation.dart';
import 'package:progressio_mobile/model/user_progress.dart';
import 'package:progressio_mobile/providers/calendar_provider.dart';
import 'package:progressio_mobile/providers/content_provider.dart';
import 'package:progressio_mobile/providers/progress_provider.dart';
import 'package:progressio_mobile/providers/recommendation_provider.dart';
import 'package:progressio_mobile/screens/content_detail_screen.dart';
import 'package:progressio_mobile/utils/app_colors.dart';
import 'package:progressio_mobile/utils/utils.dart';
import 'package:progressio_mobile/widgets/app_ui.dart';
import 'package:progressio_mobile/widgets/content_card.dart';
import 'package:progressio_mobile/widgets/section_header.dart';
import 'package:progressio_mobile/widgets/skeleton_loader.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Content> _popular = [];
  List<UserProgress> _inProgress = [];
  List<Recommendation> _recommendations = [];
  List<CalendarItem> _todayReleases = [];
  Content? _featured;

  bool _loadingPopular = true;
  bool _loadingProgress = true;
  bool _loadingRecs = true;
  bool _loadingToday = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    await Future.wait([
      _loadPopular(),
      _loadInProgress(),
      _loadRecommendations(),
      _loadToday(),
    ]);
  }

  Future<void> _loadPopular() async {
    try {
      final result = await context
          .read<ContentProvider>()
          .get(filter: {'page': 1, 'pageSize': 20, 'isActive': true});
      if (mounted) {
        setState(() {
          _popular = result.items;
          _featured = result.items.isNotEmpty ? result.items.first : null;
          _loadingPopular = false;
        });
      }
    } catch (e) {
      debugPrint('POPULAR ERROR: $e');
      if (mounted) setState(() => _loadingPopular = false);
    }
  }

  Future<void> _loadInProgress() async {
    try {
      final items = await context
          .read<ProgressProvider>()
          .getMyProgress(status: 'InProgress');
      if (mounted) {
        setState(() {
          _inProgress = items;
          _loadingProgress = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingProgress = false);
    }
  }

  Future<void> _loadRecommendations() async {
    try {
      final items =
          await context.read<RecommendationProvider>().getRecommendations();
      if (mounted) {
        setState(() {
          _recommendations = items;
          _loadingRecs = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingRecs = false);
    }
  }

  Future<void> _loadToday() async {
    try {
      final items = await context.read<CalendarProvider>().getToday();
      if (mounted) {
        setState(() {
          _todayReleases = items;
          _loadingToday = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingToday = false);
    }
  }

  void _goToDetail(int contentId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ContentDetailScreen(contentId: contentId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.card,
        onRefresh: () async {
          setState(() {
            _loadingPopular = true;
            _loadingProgress = true;
            _loadingRecs = true;
            _loadingToday = true;
          });
          await _loadAll();
        },
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(child: _buildFeaturedBanner()),
            SliverToBoxAdapter(child: _buildContinueWatching()),
            SliverToBoxAdapter(child: _buildRecommended()),
            SliverToBoxAdapter(child: _buildTodayReleases()),
            SliverToBoxAdapter(child: _buildPopular()),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  // ─── App Bar ─────────────────────────────────────────────────────────────────

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      snap: true,
      backgroundColor: AppColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      title: Row(
        children: [
          const AppBrandMark(size: 32, iconSize: 18),
          const SizedBox(width: 10),
          const Text(
            'Progressio',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.calendar_month_outlined,
              color: AppColors.textSecondary),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CalendarScreen()),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.notifications_outlined,
              color: AppColors.textSecondary),
          onPressed: () {},
        ),
      ],
    );
  }

  // ─── Featured Banner ─────────────────────────────────────────────────────────

  Widget _buildFeaturedBanner() {
    if (_loadingPopular) {
      return const SkeletonBox(width: double.infinity, height: 320, radius: 0);
    }
    if (_featured == null) return const SizedBox();

    return GestureDetector(
      onTap: () => _goToDetail(_featured!.id),
      child: SizedBox(
        width: double.infinity,
        height: 320,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _featured!.coverImageUrl != null
                ? CachedNetworkImage(
                    imageUrl: _featured!.coverImageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        Container(color: AppColors.surface),
                    errorWidget: (_, __, ___) =>
                        Container(color: AppColors.surface),
                  )
                : Container(color: AppColors.surface),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppColors.background.withOpacity(0.6),
                    AppColors.background,
                  ],
                  stops: const [0.25, 0.65, 1.0],
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: 18,
              right: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_featured!.contentTypeName != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _featured!.contentTypeName!.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  Text(
                    _featured!.title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          color: AppColors.premium, size: 15),
                      const SizedBox(width: 4),
                      Text(
                        ratingString(_featured!.avgRating),
                        style: const TextStyle(
                          color: AppColors.premium,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (_featured!.releaseYear != null) ...[
                        const SizedBox(width: 10),
                        Text(
                          '${_featured!.releaseYear}',
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 13),
                        ),
                      ],
                      if (_featured!.genres.isNotEmpty) ...[
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            _featured!.genres.take(2).join(' · '),
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _goToDetail(_featured!.id),
                        icon: const Icon(Icons.play_arrow_rounded,
                            size: 18, color: Colors.black),
                        label: const Text('View Details'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24)),
                          textStyle: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.add_rounded,
                            size: 16, color: AppColors.textSecondary),
                        label: const Text(
                          'My List',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 13),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.border),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Continue Watching ────────────────────────────────────────────────────────

  Widget _buildContinueWatching() {
    if (_loadingProgress) {
      return const SkeletonRail(title: 'Continue Watching');
    }
    if (_inProgress.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 28, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Continue Watching',
            actionLabel: 'See All',
            onAction: () {},
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 155,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _inProgress.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                final p = _inProgress[i];
                return _ProgressCard(
                  progress: p,
                  onTap: () => _goToDetail(p.contentId),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─── Recommended ─────────────────────────────────────────────────────────────

  Widget _buildRecommended() {
    if (_loadingRecs) {
      return const SkeletonRail(title: 'Recommended For You');
    }
    if (_recommendations.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 28, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Recommended For You'),
          const SizedBox(height: 14),
          SizedBox(
            height: 230,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _recommendations.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                final r = _recommendations[i];
                return _RecommendationCard(
                  rec: r,
                  onTap: () => _goToDetail(r.contentId),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─── Today Releases ───────────────────────────────────────────────────────────

  Widget _buildTodayReleases() {
    if (_loadingToday) return const SizedBox();
    if (_todayReleases.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 28, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SectionHeader(title: 'Out Today'),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${_todayReleases.length} NEW',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ..._todayReleases
              .take(5)
              .map((item) => _TodayReleaseRow(item: item)),
        ],
      ),
    );
  }

  // ─── Popular ──────────────────────────────────────────────────────────────────

  Widget _buildPopular() {
    if (_loadingPopular) return const SkeletonRail(title: 'Popular');
    if (_popular.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 28, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Popular',
            actionLabel: 'See All',
            onAction: () {},
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 250,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _popular.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                final c = _popular[i];
                return ContentCard(
                  contentId: c.id,
                  title: c.title,
                  coverImageUrl: c.coverImageUrl,
                  contentTypeName: c.contentTypeName,
                  avgRating: c.avgRating,
                  onTap: () => _goToDetail(c.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Progress Card ────────────────────────────────────────────────────────────
// ProgressResponse ne sadrži coverImageUrl — prikazujemo placeholder

class _ProgressCard extends StatelessWidget {
  final UserProgress progress;
  final VoidCallback onTap;

  const _ProgressCard({required this.progress, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 130,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      color: AppColors.surface,
                      child: const Center(
                        child: Icon(Icons.movie_rounded,
                            color: AppColors.textFaint, size: 28),
                      ),
                    ),
                    Positioned(
                      bottom: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Text(
                          'IN PROGRESS',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              progress.contentTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (progress.lastActivityAt != null)
              Text(
                timeAgo(progress.lastActivityAt),
                style: const TextStyle(
                  color: AppColors.textFaint,
                  fontSize: 11,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Recommendation Card ──────────────────────────────────────────────────────
// RecommendationResponse nema genres — prikazujemo samo naziv i rating

class _RecommendationCard extends StatelessWidget {
  final Recommendation rec;
  final VoidCallback onTap;

  const _RecommendationCard({required this.rec, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 110,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 2 / 3,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    rec.coverImageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: rec.coverImageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) =>
                                Container(color: AppColors.surface),
                            errorWidget: (_, __, ___) =>
                                Container(color: AppColors.surface),
                          )
                        : Container(
                            color: AppColors.surface,
                            child: const Center(
                              child: Icon(Icons.movie_rounded,
                                  color: AppColors.textFaint, size: 28),
                            ),
                          ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.overlay,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded,
                                color: AppColors.premium, size: 11),
                            const SizedBox(width: 2),
                            Text(
                              ratingString(rec.avgRating),
                              style: const TextStyle(
                                color: AppColors.premium,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              rec.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
            if (rec.explanationText.isNotEmpty) ...[
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  rec.explanationText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Today Release Row ────────────────────────────────────────────────────────
// CalendarItemResponse nema coverImageUrl — prikazujemo ikonu tipa sadržaja

class _TodayReleaseRow extends StatelessWidget {
  final CalendarItem item;

  const _TodayReleaseRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Icon(
                item.itemType.toLowerCase() == 'episode'
                    ? Icons.play_circle_outline_rounded
                    : Icons.menu_book_rounded,
                color: AppColors.textMuted,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.contentTitle,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  item.title,
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: item.itemType.toLowerCase() == 'episode'
                      ? AppColors.secondary.withOpacity(0.15)
                      : AppColors.warning.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.itemType,
                  style: TextStyle(
                    color: item.itemType.toLowerCase() == 'episode'
                        ? AppColors.secondary
                        : AppColors.warning,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (item.releaseDetails.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  item.releaseDetails,
                  style: const TextStyle(
                      color: AppColors.textFaint, fontSize: 11),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}