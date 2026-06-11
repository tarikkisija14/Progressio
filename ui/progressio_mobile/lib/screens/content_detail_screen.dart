// lib/screens/content_detail_screen.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:progressio_mobile/model/chapter.dart';
import 'package:progressio_mobile/model/character.dart';
import 'package:progressio_mobile/model/content.dart';
import 'package:progressio_mobile/model/episode.dart';
import 'package:progressio_mobile/model/review.dart';
import 'package:progressio_mobile/model/season.dart';
import 'package:progressio_mobile/model/user_progress.dart';
import 'package:progressio_mobile/providers/chapter_provider.dart';
import 'package:progressio_mobile/providers/character_provider.dart';
import 'package:progressio_mobile/providers/content_provider.dart';
import 'package:progressio_mobile/providers/episode_provider.dart';
import 'package:progressio_mobile/providers/progress_provider.dart';
import 'package:progressio_mobile/providers/review_provider.dart';
import 'package:progressio_mobile/providers/season_provider.dart';
import 'package:progressio_mobile/utils/app_colors.dart';
import 'package:progressio_mobile/utils/utils.dart';
import 'package:progressio_mobile/widgets/app_ui.dart';

class ContentDetailScreen extends StatefulWidget {
  final int contentId;

  const ContentDetailScreen({super.key, required this.contentId});

  @override
  State<ContentDetailScreen> createState() => _ContentDetailScreenState();
}

class _ContentDetailScreenState extends State<ContentDetailScreen>
    with SingleTickerProviderStateMixin {
  Content? _content;
  UserProgress? _progress;
  List<Season> _seasons = [];
  List<Chapter> _chapters = [];
  List<Character> _characters = [];
  List<Review> _reviews = [];

  bool _loadingContent = true;
  bool _loadingSeasons = false;
  bool _loadingChapters = false;
  bool _loadingCharacters = false;
  bool _loadingReviews = false;
  bool _updatingStatus = false;

  late TabController _tabController;

  // episode cache po sezoni
  final Map<int, List<Episode>> _episodeCache = {};
  final Map<int, bool> _seasonExpanded = {};

  bool get _isSeriesType {
    final t = _content?.contentTypeName?.toLowerCase() ?? '';
    return t.contains('anime') || t.contains('series') || t.contains('tv');
  }

  bool get _isBookType {
    final t = _content?.contentTypeName?.toLowerCase() ?? '';
    return t.contains('manga') || t.contains('book') || t.contains('novel');
  }

  List<String> get _tabs {
    if (_isSeriesType) return ['Info', 'Episodes', 'Characters', 'Reviews'];
    if (_isBookType) return ['Info', 'Chapters', 'Characters', 'Reviews'];
    return ['Info', 'Characters', 'Reviews'];
  }

  @override
  void initState() {
    super.initState();
    // Inicijalizujemo s 3 taba — bit će reinicijalizovano nakon load-a
    // kada se zna tip sadrzaja (_tabs.length moze biti 3 ili 4)
    _tabController = TabController(length: 3, vsync: this);
    _loadContent();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Reinicijalizuje TabController na ispravan broj tabova nakon sto se
  /// ucita sadrzaj i zna se tip (serija/knjiga/film).
  void _reinitTabController() {
    final newLength = _tabs.length;
    if (_tabController.length != newLength) {
      _tabController.dispose();
      _tabController = TabController(length: newLength, vsync: this);
    }
  }

  Future<void> _loadContent() async {
    try {
      final content =
          await context.read<ContentProvider>().getById(widget.contentId);

      final progress =
          await context.read<ProgressProvider>().getForContent(widget.contentId);

      if (!mounted) return;

      setState(() {
        _content = content;
        _progress = progress;
        _loadingContent = false;
      });

      // Reinicijalizuj TabController sada kada znamo tip sadrzaja
      _reinitTabController();

      final t = content.contentTypeName?.toLowerCase() ?? '';
      final isSeries =
          t.contains('anime') || t.contains('series') || t.contains('tv');
      final isBook =
          t.contains('manga') || t.contains('book') || t.contains('novel');

      _loadCharacters();
      _loadReviews();

      if (isSeries) {
        _loadSeasons();
      }

      if (isBook) {
        _loadChapters();
      }
    } catch (e) {
      debugPrint('ContentDetailScreen load error: $e');
      if (mounted) {
        setState(() {
          _loadingContent = false;
        });
      }
    }
  }

  Future<void> _loadSeasons() async {
    setState(() => _loadingSeasons = true);
    try {
      final result = await context.read<SeasonProvider>().get(
            filter: {'contentId': widget.contentId, 'page': 1, 'pageSize': 50},
          );
      if (mounted) {
        setState(() {
          _seasons = result.items;
          _loadingSeasons = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingSeasons = false);
    }
  }

  Future<void> _loadChapters() async {
    setState(() => _loadingChapters = true);
    try {
      final result = await context.read<ChapterProvider>().get(
            filter: {
              'contentId': widget.contentId,
              'page': 1,
              'pageSize': 200
            },
          );
      if (mounted) {
        setState(() {
          _chapters = result.items;
          _loadingChapters = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingChapters = false);
    }
  }

  Future<void> _loadEpisodesForSeason(int seasonId) async {
    if (_episodeCache.containsKey(seasonId)) return;
    try {
      final result = await context.read<EpisodeProvider>().get(
            filter: {'seasonId': seasonId, 'page': 1, 'pageSize': 100},
          );
      if (mounted) setState(() => _episodeCache[seasonId] = result.items);
    } catch (_) {}
  }

  Future<void> _loadCharacters() async {
    setState(() => _loadingCharacters = true);
    try {
      final result = await context.read<CharacterProvider>().get(
            filter: {
              'contentId': widget.contentId,
              'page': 1,
              'pageSize': 50
            },
          );
      if (mounted) {
        setState(() {
          _characters = result.items;
          _loadingCharacters = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingCharacters = false);
    }
  }

  Future<void> _loadReviews() async {
    setState(() => _loadingReviews = true);
    try {
      final reviews = await context
          .read<ReviewProvider>()
          .getForContent(widget.contentId);
      if (mounted) {
        setState(() {
          _reviews = reviews;
          _loadingReviews = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingReviews = false);
    }
  }

  /// Pokretanje pracenja — POST /api/progress/start
  Future<void> _startProgress() async {
    setState(() => _updatingStatus = true);
    try {
      final progress = await context
          .read<ProgressProvider>()
          .startProgress(widget.contentId);
      if (mounted) setState(() {
        _progress = progress;
        _updatingStatus = false;
      });
    } catch (_) {
      if (mounted) setState(() => _updatingStatus = false);
    }
  }

  /// Promjena statusa — PUT /api/progress/{progressId}/status
  Future<void> _changeStatus(String newStatus) async {
    final p = _progress;
    if (p == null) return;
    setState(() => _updatingStatus = true);
    try {
      final updated = await context
          .read<ProgressProvider>()
          .changeStatus(p.id, newStatus);
      if (mounted) setState(() {
        _progress = updated;
        _updatingStatus = false;
      });
    } catch (_) {
      if (mounted) setState(() => _updatingStatus = false);
    }
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loadingContent) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    if (_content == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(backgroundColor: AppColors.background),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  color: AppColors.textMuted, size: 48),
              const SizedBox(height: 12),
              const Text('Could not load content.',
                  style: TextStyle(color: AppColors.textMuted)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() => _loadingContent = true);
                  _loadContent();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          _buildHeroHeader(),
          _buildTabBar(),
        ],
        body: TabBarView(
          controller: _tabController,
          children: _buildTabViews(),
        ),
      ),
    );
  }

  // ─── Hero Header ────────────────────────────────────────────────────────────

  Widget _buildHeroHeader() {
    final c = _content!;
    return SliverAppBar(
      expandedHeight: 340,
      pinned: true,
      backgroundColor: AppColors.background,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 16),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Stack(
          fit: StackFit.expand,
          children: [
            c.coverImageUrl != null
                ? CachedNetworkImage(
                    imageUrl: c.coverImageUrl!,
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
                    AppColors.background.withOpacity(0.7),
                    AppColors.background,
                  ],
                  stops: const [0.3, 0.7, 1.0],
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 18,
              right: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (c.contentTypeName != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        c.contentTypeName!.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  Text(
                    c.title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 24,
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
                        ratingString(c.avgRating),
                        style: const TextStyle(
                          color: AppColors.premium,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '(${c.totalRatings})',
                        style: const TextStyle(
                            color: AppColors.textFaint, fontSize: 12),
                      ),
                      if (c.releaseYear != null) ...[
                        const SizedBox(width: 10),
                        Text('${c.releaseYear}',
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 13)),
                      ],
                    ],
                  ),
                  if (c.genres.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: c.genres
                          .take(4)
                          .map((g) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Text(g,
                                    style: const TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 11)),
                              ))
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 12),
                  _buildStatusButtons(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusButtons() {
    if (_updatingStatus) {
      return const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
            color: AppColors.primary, strokeWidth: 2),
      );
    }

    final status = _progress?.status;

    if (status == null || status == 'Cancelled') {
      return _statusBtn('Start Watching', AppColors.primary, Colors.black,
          () => _startProgress());
    }

    switch (status) {
      case 'InProgress':
        return Wrap(
          spacing: 8,
          children: [
            _statusBtn('Complete', AppColors.success, Colors.white,
                () => _changeStatus('Completed')),
            _statusBtn('On Hold', AppColors.warning, Colors.black,
                () => _changeStatus('OnHold')),
            _statusBtn('Drop', AppColors.error, Colors.white,
                () => _changeStatus('Cancelled')),
          ],
        );
      case 'OnHold':
        return Wrap(
          spacing: 8,
          children: [
            _statusBtn('Resume', AppColors.primary, Colors.black,
                () => _changeStatus('InProgress')),
            _statusBtn('Drop', AppColors.error, Colors.white,
                () => _changeStatus('Cancelled')),
          ],
        );
      case 'Completed':
        return _statusBtn('Re-watch', AppColors.secondary, Colors.black,
            () => _changeStatus('InProgress'));
      default:
        return const SizedBox();
    }
  }

  Widget _statusBtn(
      String label, Color bg, Color fg, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        textStyle:
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
      child: Text(label),
    );
  }

  // ─── Tab Bar ────────────────────────────────────────────────────────────────

  Widget _buildTabBar() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _TabBarDelegate(
        TabBar(
          controller: _tabController,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          unselectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          indicatorColor: AppColors.primary,
          indicatorWeight: 2,
          isScrollable: _tabs.length > 3,
          dividerColor: AppColors.divider,
        ),
      ),
    );
  }

  List<Widget> _buildTabViews() {
    final views = <Widget>[_buildInfoTab()];
    if (_isSeriesType) views.add(_buildEpisodesTab());
    if (_isBookType) views.add(_buildChaptersTab());
    views.add(_buildCharactersTab());
    views.add(_buildReviewsTab());
    return views;
  }

  // ─── Info Tab ────────────────────────────────────────────────────────────────

  Widget _buildInfoTab() {
    final c = _content!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_progress != null) _buildProgressCard(),
          if (c.description != null && c.description!.isNotEmpty) ...[
            const SizedBox(height: 4),
            const Text('Synopsis',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            _ExpandableText(text: c.description!),
            const SizedBox(height: 20),
          ],
          const Text('Details',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          if (c.contentTypeName != null)
            _detailRow('Type', c.contentTypeName!),
          if (c.releaseYear != null)
            _detailRow('Year', '${c.releaseYear}'),
          if (c.languageName != null)
            _detailRow('Language', c.languageName!),
          if (c.ageRatingName != null)
            _detailRow('Age Rating', c.ageRatingName!),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
    final p = _progress!;
    final watched = p.watchedEpisodesCount;
    final total = p.totalEpisodesCount;
    final read = p.readChaptersCount;
    final totalCh = p.totalChaptersCount;

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(14),
      decoration: AppDecorations.panel(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(p.status).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  p.status,
                  style: TextStyle(
                    color: _statusColor(p.status),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              if (p.startedAt != null)
                Text(
                  'Since ${formatDate(p.startedAt)}',
                  style: const TextStyle(
                      color: AppColors.textFaint, fontSize: 11),
                ),
            ],
          ),
          if (total > 0) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Episodes watched',
                    style:
                        TextStyle(color: AppColors.textMuted, fontSize: 12)),
                Text('$watched / $total',
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: total > 0 ? watched / total : 0,
                backgroundColor: AppColors.surface,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.primary),
                minHeight: 4,
              ),
            ),
          ],
          if (totalCh > 0) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Chapters read',
                    style:
                        TextStyle(color: AppColors.textMuted, fontSize: 12)),
                Text('$read / $totalCh',
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: totalCh > 0 ? read / totalCh : 0,
                backgroundColor: AppColors.surface,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.primary),
                minHeight: 4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'InProgress':
        return AppColors.primary;
      case 'Completed':
        return AppColors.success;
      case 'OnHold':
        return AppColors.warning;
      case 'Cancelled':
        return AppColors.error;
      default:
        return AppColors.textMuted;
    }
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: const TextStyle(
                    color: AppColors.textFaint, fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  // ─── Episodes Tab ────────────────────────────────────────────────────────────

  Widget _buildEpisodesTab() {
    if (_loadingSeasons) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_seasons.isEmpty) {
      return const Center(
          child: Text('No episodes available.',
              style: TextStyle(color: AppColors.textMuted)));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _seasons.length,
      itemBuilder: (_, i) {
        final season = _seasons[i];
        final isExpanded = _seasonExpanded[season.id] ?? false;
        final episodes = _episodeCache[season.id] ?? [];
        return _SeasonTile(
          season: season,
          episodes: episodes,
          isExpanded: isExpanded,
          onToggle: () {
            setState(() => _seasonExpanded[season.id] = !isExpanded);
            if (!isExpanded) _loadEpisodesForSeason(season.id);
          },
          progressId: _progress?.id,
          onMarkEpisode: (episodeId) async {
            if (_progress != null) {
              await context
                  .read<ProgressProvider>()
                  .markEpisode(_progress!.id, episodeId, true);
              final updated = await context
                  .read<ProgressProvider>()
                  .getForContent(widget.contentId);
              if (mounted) setState(() => _progress = updated);
            }
          },
        );
      },
    );
  }

  // ─── Chapters Tab ────────────────────────────────────────────────────────────

  Widget _buildChaptersTab() {
    if (_loadingChapters) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_chapters.isEmpty) {
      return const Center(
          child: Text('No chapters available.',
              style: TextStyle(color: AppColors.textMuted)));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _chapters.length,
      itemBuilder: (_, i) {
        final ch = _chapters[i];
        return ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${ch.chapterNumber}',
                style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),
          title: Text(ch.title,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
          subtitle: ch.releaseDate != null
              ? Text(formatDate(ch.releaseDate),
                  style: const TextStyle(
                      color: AppColors.textFaint, fontSize: 12))
              : null,
          trailing: _progress != null
              ? IconButton(
                  icon: const Icon(Icons.check_circle_outline,
                      color: AppColors.textFaint, size: 20),
                  onPressed: () async {
                    await context
                        .read<ProgressProvider>()
                        .markChapter(_progress!.id, ch.id, true);
                    final updated = await context
                        .read<ProgressProvider>()
                        .getForContent(widget.contentId);
                    if (mounted) setState(() => _progress = updated);
                  },
                )
              : null,
        );
      },
    );
  }

  // ─── Characters Tab ──────────────────────────────────────────────────────────

  Widget _buildCharactersTab() {
    if (_loadingCharacters) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_characters.isEmpty) {
      return const Center(
          child: Text('No characters.',
              style: TextStyle(color: AppColors.textMuted)));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(18),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _characters.length,
      itemBuilder: (_, i) => _CharacterCard(character: _characters[i]),
    );
  }

  // ─── Reviews Tab ─────────────────────────────────────────────────────────────

  Widget _buildReviewsTab() {
    if (_loadingReviews) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_reviews.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.rate_review_outlined,
                color: AppColors.textFaint, size: 48),
            SizedBox(height: 12),
            Text('No reviews yet.',
                style: TextStyle(color: AppColors.textMuted)),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(18),
      itemCount: _reviews.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _ReviewCard(review: _reviews[i]),
    );
  }
}

// ─── Season Tile ──────────────────────────────────────────────────────────────

class _SeasonTile extends StatelessWidget {
  final Season season;
  final List<Episode> episodes;
  final bool isExpanded;
  final VoidCallback onToggle;
  final int? progressId;
  final Future<void> Function(int episodeId) onMarkEpisode;

  const _SeasonTile({
    required this.season,
    required this.episodes,
    required this.isExpanded,
    required this.onToggle,
    required this.progressId,
    required this.onMarkEpisode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onToggle,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      'S${season.seasonNumber}',
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        season.title,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${season.episodeCount} episodes'
                        '${season.releaseYear != null ? ' · ${season.releaseYear}' : ''}',
                        style: const TextStyle(
                            color: AppColors.textFaint, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
        if (isExpanded)
          episodes.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: AppColors.primary, strokeWidth: 2),
                    ),
                  ),
                )
              : Column(
                  children: episodes
                      .map((e) => _EpisodeTile(
                            episode: e,
                            canMark: progressId != null,
                            onMark: () => onMarkEpisode(e.id),
                          ))
                      .toList(),
                ),
        const Divider(height: 1, color: AppColors.divider),
      ],
    );
  }
}

class _EpisodeTile extends StatelessWidget {
  final Episode episode;
  final bool canMark;
  final VoidCallback onMark;

  const _EpisodeTile({
    required this.episode,
    required this.canMark,
    required this.onMark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(66, 0, 18, 0),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(
              'E${episode.episodeNumber}',
              style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ),
        title: Text(
          episode.title,
          style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w400),
        ),
        subtitle: Text(
          formatDate(episode.airDate),
          style:
              const TextStyle(color: AppColors.textFaint, fontSize: 11),
        ),
        trailing: canMark
            ? IconButton(
                icon: const Icon(Icons.check_circle_outline,
                    color: AppColors.textFaint, size: 18),
                onPressed: onMark,
              )
            : null,
      ),
    );
  }
}

// ─── Character Card ───────────────────────────────────────────────────────────

class _CharacterCard extends StatelessWidget {
  final Character character;

  const _CharacterCard({required this.character});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppDecorations.panel(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(40),
            child: SizedBox(
              width: 72,
              height: 72,
              child: character.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: character.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(color: AppColors.surface),
                      errorWidget: (_, __, ___) => Container(
                        color: AppColors.surface,
                        child: const Icon(Icons.person_rounded,
                            color: AppColors.textFaint, size: 32),
                      ),
                    )
                  : Container(
                      color: AppColors.surface,
                      child: const Icon(Icons.person_rounded,
                          color: AppColors.textFaint, size: 32),
                    ),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              character.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          ),
          // Backend vraca isMainCharacter (bool), NE role (String)
          if (character.isMainCharacter) ...[
            const SizedBox(height: 4),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Main',
                style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Review Card ──────────────────────────────────────────────────────────────

class _ReviewCard extends StatefulWidget {
  final Review review;

  const _ReviewCard({required this.review});

  @override
  State<_ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<_ReviewCard> {
  bool _showSpoiler = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.review;
    // Backend vraca userFullName, ne username
    final displayName =
        r.userFullName.isNotEmpty ? r.userFullName : 'Anonymous';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppDecorations.panel(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.surface,
                child: Text(
                  displayName[0].toUpperCase(),
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                    ),
                    Text(
                      timeAgo(r.createdAt),
                      style: const TextStyle(
                          color: AppColors.textFaint, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < r.rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: AppColors.premium,
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
          if (r.title != null && r.title!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              r.title!,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700),
            ),
          ],
          if (r.body != null && r.body!.isNotEmpty) ...[
            const SizedBox(height: 8),
            if (r.hasSpoiler && !_showSpoiler)
              GestureDetector(
                onTap: () => setState(() => _showSpoiler = true),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColors.warning.withOpacity(0.3)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: AppColors.warning, size: 14),
                      SizedBox(width: 6),
                      Text('Spoiler — tap to reveal',
                          style: TextStyle(
                              color: AppColors.warning,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              )
            else
              Text(
                r.body!,
                style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.5),
              ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.thumb_up_outlined,
                  color: AppColors.textFaint, size: 14),
              const SizedBox(width: 4),
              Text('${r.likeCount}',
                  style: const TextStyle(
                      color: AppColors.textFaint, fontSize: 12)),
              if (r.hasSpoiler) ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('SPOILER',
                      style: TextStyle(
                          color: AppColors.warning,
                          fontSize: 9,
                          fontWeight: FontWeight.w800)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Expandable Text ──────────────────────────────────────────────────────────

class _ExpandableText extends StatefulWidget {
  final String text;

  const _ExpandableText({required this.text});

  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.text,
          maxLines: _expanded ? null : 4,
          overflow: _expanded ? null : TextOverflow.ellipsis,
          style: const TextStyle(
              color: AppColors.textSecondary, fontSize: 13, height: 1.6),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Text(
            _expanded ? 'Show less' : 'Read more',
            style: const TextStyle(
                color: AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

// ─── TabBar Delegate ──────────────────────────────────────────────────────────

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.background,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) => false;
}