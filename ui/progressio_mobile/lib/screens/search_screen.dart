import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:progressio_mobile/model/content.dart';
import 'package:progressio_mobile/model/content_type.dart';
import 'package:progressio_mobile/model/genre.dart';
import 'package:progressio_mobile/providers/content_provider.dart';
import 'package:progressio_mobile/providers/content_type_provider.dart';
import 'package:progressio_mobile/providers/genre_provider.dart';
import 'package:progressio_mobile/screens/content_detail_screen.dart';
import 'package:progressio_mobile/utils/app_colors.dart';
import 'package:progressio_mobile/utils/utils.dart';
import 'package:progressio_mobile/widgets/app_ui.dart';
import 'package:progressio_mobile/widgets/skeleton_loader.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _queryController = TextEditingController();
  final _scrollController = ScrollController();

  List<Content> _results = [];
  bool _loading = false;
  bool _loadingMore = false;
  bool _hasMore = false;
  int _page = 1;
  String _query = '';

  // Filters
  int? _selectedGenreId;
  int? _selectedTypeId;
  List<Genre> _genres = [];
  List<ContentType> _contentTypes = [];
  bool _loadingFilters = true;

  @override
  void initState() {
    super.initState();
    _loadFilters();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _queryController.dispose();
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

  Future<void> _loadFilters() async {
    try {
      final genres =
          await context.read<GenreProvider>().get(filter: {'pageSize': 100});
      final types = await context
          .read<ContentTypeProvider>()
          .get(filter: {'pageSize': 50});
      if (mounted) {
        setState(() {
          _genres = genres.items;
          _contentTypes = types.items;
          _loadingFilters = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingFilters = false);
    }
  }

  Future<void> _search() async {
    final q = _queryController.text.trim();
    setState(() {
      _query = q;
      _loading = true;
      _page = 1;
      _results = [];
      _hasMore = false;
    });

    final filter = _buildFilter(page: 1);
    try {
      final result =
          await context.read<ContentProvider>().get(filter: filter);
      if (mounted) {
        setState(() {
          _results = result.items;
          _hasMore = result.items.length >= 20;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Search error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    final nextPage = _page + 1;
    final filter = _buildFilter(page: nextPage);
    try {
      final result =
          await context.read<ContentProvider>().get(filter: filter);
      if (mounted) {
        setState(() {
          _results.addAll(result.items);
          _page = nextPage;
          _hasMore = result.items.length >= 20;
          _loadingMore = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Map<String, dynamic> _buildFilter({required int page}) {
    final filter = <String, dynamic>{
      'page': page,
      'pageSize': 20,
      'isActive': true,
    };
    if (_query.isNotEmpty) filter['title'] = _query;
    if (_selectedGenreId != null) filter['genreId'] = _selectedGenreId;
    if (_selectedTypeId != null) filter['contentTypeId'] = _selectedTypeId;
    return filter;
  }

  void _clearFilters() {
    setState(() {
      _selectedGenreId = null;
      _selectedTypeId = null;
    });
    if (_query.isNotEmpty || _results.isNotEmpty) _search();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppShellBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildSearchBar(),
              if (!_loadingFilters) _buildFilterChips(),
              const Divider(color: AppColors.hairline, height: 1),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _queryController,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search titles…',
                hintStyle: const TextStyle(color: AppColors.textFaint),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppColors.textMuted),
                suffixIcon: _queryController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: AppColors.textMuted, size: 18),
                        onPressed: () {
                          _queryController.clear();
                          _search();
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.input,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _search(),
              textInputAction: TextInputAction.search,
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _search,
            child: Container(
              width: 46,
              height: 46,
              decoration: AppDecorations.brandedMark(radius: AppRadii.md),
              child: _loading
                  ? const Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.black),
                      ),
                    )
                  : const Icon(Icons.search, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final bool hasActiveFilter =
        _selectedGenreId != null || _selectedTypeId != null;

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        children: [
          if (hasActiveFilter)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                label: const Text('Clear'),
                avatar: const Icon(Icons.close_rounded, size: 14),
                onPressed: _clearFilters,
                backgroundColor: AppColors.error.withOpacity(0.12),
                labelStyle: const TextStyle(
                    color: AppColors.error, fontSize: 12),
                side: const BorderSide(color: AppColors.error),
              ),
            ),
          // Type filter
          ..._contentTypes.map((ct) {
            final selected = _selectedTypeId == ct.id;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(ct.name),
                selected: selected,
                onSelected: (v) {
                  setState(() =>
                      _selectedTypeId = v ? ct.id : null);
                  _search();
                },
                selectedColor: AppColors.primarySoft,
                checkmarkColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: selected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  fontSize: 12,
                ),
                side: BorderSide(
                  color:
                      selected ? AppColors.primary : AppColors.border,
                ),
                backgroundColor: AppColors.card,
              ),
            );
          }),
          // Genre filter
          ..._genres.take(10).map((g) {
            final selected = _selectedGenreId == g.id;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(g.name),
                selected: selected,
                onSelected: (v) {
                  setState(
                      () => _selectedGenreId = v ? g.id : null);
                  _search();
                },
                selectedColor: AppColors.primarySoft,
                checkmarkColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: selected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  fontSize: 12,
                ),
                side: BorderSide(
                  color:
                      selected ? AppColors.primary : AppColors.border,
                ),
                backgroundColor: AppColors.card,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return GridView.builder(
        padding: const EdgeInsets.all(AppSpacing.lg),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.6,
        ),
        itemCount: 9,
        itemBuilder: (_, __) =>
            const SkeletonBox(width: double.infinity, height: double.infinity),
      );
    }

    if (_results.isEmpty) {
      return _buildEmptyState();
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (_) => false,
      child: GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(AppSpacing.lg),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.6,
        ),
        itemCount: _results.length + (_loadingMore ? 3 : 0),
        itemBuilder: (_, i) {
          if (i >= _results.length) {
            return const SkeletonBox(
                width: double.infinity, height: double.infinity);
          }
          final c = _results[i];
          return _SearchResultCard(
            content: c,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      ContentDetailScreen(contentId: c.id)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    if (_query.isEmpty &&
        _selectedGenreId == null &&
        _selectedTypeId == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.search_rounded,
                color: AppColors.textFaint, size: 52),
            SizedBox(height: 14),
            Text(
              'Search for anime, manga, series, games…',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
          ],
        ),
      );
    }
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off_rounded,
              color: AppColors.textFaint, size: 52),
          const SizedBox(height: 14),
          Text(
            'No results for "$_query"',
            style:
                const TextStyle(color: AppColors.textMuted, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  final Content content;
  final VoidCallback onTap;

  const _SearchResultCard({required this.content, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  content.coverImageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: content.coverImageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              Container(color: AppColors.surface),
                          errorWidget: (_, __, ___) =>
                              Container(color: AppColors.surface,
                                  child: const Center(child: Icon(
                                      Icons.movie_rounded,
                                      color: AppColors.textFaint,
                                      size: 24))),
                        )
                      : Container(
                          color: AppColors.surface,
                          child: const Center(
                            child: Icon(Icons.movie_rounded,
                                color: AppColors.textFaint, size: 24),
                          ),
                        ),
                  Positioned(
                    top: 5,
                    right: 5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.overlay,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded,
                              color: AppColors.premium, size: 10),
                          const SizedBox(width: 2),
                          Text(
                            ratingString(content.avgRating),
                            style: const TextStyle(
                              color: AppColors.premium,
                              fontSize: 9,
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
          const SizedBox(height: 5),
          Text(
            content.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
          if (content.contentTypeName != null)
            Text(
              content.contentTypeName!,
              style: const TextStyle(
                  color: AppColors.textFaint, fontSize: 10),
            ),
        ],
      ),
    );
  }
}