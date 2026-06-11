import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:progressio_mobile/model/content.dart';
import 'package:progressio_mobile/providers/content_provider.dart';
import 'package:progressio_mobile/providers/base_provider.dart';
import 'package:progressio_mobile/screens/content_detail_screen.dart';
import 'package:progressio_mobile/utils/app_colors.dart';
import 'package:progressio_mobile/widgets/skeleton_loader.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  final _focusNode = FocusNode();

  List<Content> _results = [];
  bool _loading = false;
  bool _searched = false;

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      setState(() {
        _results = [];
        _searched = false;
      });
      return;
    }
    setState(() => _loading = true);
    try {
      final result = await context
          .read<ContentProvider>()
          .get(filter: {'page': 1, 'pageSize': 30, 'title': q, 'isActive': true});
      if (mounted) {
        setState(() {
          _results = result.items;
          _searched = true;
          _loading = false;
        });
        // Faza 13 — log pretrage kao signal za recommender
        // POST /api/searchlogs  (fire and forget, ne blokiramo UI)
        _logSearch(q, result.items.length);
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// POST /api/searchlogs — bilježi pretragu za recommender signal.
  /// Fire-and-forget: greška se tiho zanemaruje da ne prekida UX.
  void _logSearch(String query, int resultCount) {
    context.read<ContentProvider>().postRaw('searchlogs', {
      'query': query,
      'resultCount': resultCount,
    }).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextField(
        controller: _ctrl,
        focusNode: _focusNode,
        autofocus: false,
        textInputAction: TextInputAction.search,
        onSubmitted: _search,
        onChanged: (v) {
          if (v.isEmpty) {
            setState(() {
              _results = [];
              _searched = false;
            });
          }
        },
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: 'Search movies, series, books…',
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textFaint),
          suffixIcon: _ctrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textFaint),
                  onPressed: () {
                    _ctrl.clear();
                    setState(() {
                      _results = [];
                      _searched = false;
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.input,
          hintStyle: const TextStyle(color: AppColors.textFaint),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return _buildSkeleton();
    if (!_searched) return _buildEmptyState();
    if (_results.isEmpty) return _buildNoResults();
    return _buildResults();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_rounded, color: AppColors.textFaint, size: 56),
          const SizedBox(height: 16),
          const Text(
            'Search for content',
            style: TextStyle(color: AppColors.textMuted, fontSize: 16),
          ),
          const SizedBox(height: 6),
          const Text(
            'Movies, series, anime, books, games…',
            style: TextStyle(color: AppColors.textFaint, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off_rounded, color: AppColors.textFaint, size: 56),
          const SizedBox(height: 16),
          Text(
            'No results for "${_ctrl.text}"',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: _results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 2),
      itemBuilder: (_, i) => _SearchResultTile(
        content: _results[i],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ContentDetailScreen(contentId: _results[i].id),
          ),
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: 8,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, __) => const _SearchSkeletonTile(),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  final Content content;
  final VoidCallback onTap;

  const _SearchResultTile({required this.content, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            _buildCover(),
            const SizedBox(width: 12),
            Expanded(child: _buildInfo()),
          ],
        ),
      ),
    );
  }

  Widget _buildCover() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 48,
        height: 72,
        child: content.coverImageUrl != null && content.coverImageUrl!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: content.coverImageUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: AppColors.surface),
                errorWidget: (_, __, ___) => _noImage(),
              )
            : _noImage(),
      ),
    );
  }

  Widget _noImage() => Container(
        color: AppColors.surface,
        child: const Icon(Icons.movie_rounded, color: AppColors.textFaint, size: 20),
      );

  Widget _buildInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          content.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            if (content.contentTypeName != null)
              _chip(content.contentTypeName!, AppColors.primarySoft, AppColors.primary),
            if (content.releaseYear != null) ...[
              const SizedBox(width: 6),
              Text(
                '${content.releaseYear}',
                style: const TextStyle(color: AppColors.textFaint, fontSize: 12),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.star_rounded, color: AppColors.premium, size: 13),
            const SizedBox(width: 3),
            Text(
              content.avgRating.toStringAsFixed(1),
              style: const TextStyle(color: AppColors.premium, fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 6),
            Text(
              '(${content.totalRatings})',
              style: const TextStyle(color: AppColors.textFaint, fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }

  Widget _chip(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

class _SearchSkeletonTile extends StatelessWidget {
  const _SearchSkeletonTile();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        children: [
          SkeletonBox(width: 48, height: 72, radius: 8),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: double.infinity, height: 14),
                SizedBox(height: 6),
                SkeletonBox(width: 80, height: 20),
                SizedBox(height: 6),
                SkeletonBox(width: 60, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}