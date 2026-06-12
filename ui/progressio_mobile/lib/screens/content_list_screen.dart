import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:progressio_mobile/model/content.dart';
import 'package:progressio_mobile/providers/content_provider.dart';
import 'package:progressio_mobile/screens/content_detail_screen.dart';
import 'package:progressio_mobile/utils/app_colors.dart';
import 'package:progressio_mobile/utils/utils.dart';
import 'package:progressio_mobile/widgets/app_ui.dart';
import 'package:progressio_mobile/widgets/skeleton_loader.dart';

/// Reusable full-page content grid. Pass [title] and [filter] to control
/// what is shown. Used by "See All" buttons throughout the app.
class ContentListScreen extends StatefulWidget {
  final String title;
  final Map<String, dynamic> filter;

  const ContentListScreen({
    super.key,
    required this.title,
    required this.filter,
  });

  @override
  State<ContentListScreen> createState() => _ContentListScreenState();
}

class _ContentListScreenState extends State<ContentListScreen> {
  final _scrollController = ScrollController();
  List<Content> _items = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = false;
  int _page = 1;

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
      _items = [];
    });
    try {
      final f = {...widget.filter, 'page': 1, 'pageSize': 20};
      final result =
          await context.read<ContentProvider>().get(filter: f);
      if (mounted) {
        setState(() {
          _items = result.items;
          _hasMore = result.items.length >= 20;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('ContentListScreen load error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    setState(() => _loadingMore = true);
    final nextPage = _page + 1;
    try {
      final f = {...widget.filter, 'page': nextPage, 'pageSize': 20};
      final result =
          await context.read<ContentProvider>().get(filter: f);
      if (mounted) {
        setState(() {
          _items.addAll(result.items);
          _page = nextPage;
          _hasMore = result.items.length >= 20;
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
        title: Text(
          widget.title,
          style: const TextStyle(
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
              : _items.isEmpty
                  ? _buildEmpty()
                  : GridView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 0.6,
                      ),
                      itemCount:
                          _items.length + (_loadingMore ? 3 : 0),
                      itemBuilder: (_, i) {
                        if (i >= _items.length) {
                          return const SkeletonBox(
                              width: double.infinity,
                              height: double.infinity);
                        }
                        final c = _items[i];
                        return _ContentGridCard(
                          content: c,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ContentDetailScreen(
                                  contentId: c.id),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.6,
      ),
      itemCount: 9,
      itemBuilder: (_, __) => const SkeletonBox(
          width: double.infinity, height: double.infinity),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Text(
        'Nothing here yet.',
        style: TextStyle(color: AppColors.textMuted, fontSize: 15),
      ),
    );
  }
}

class _ContentGridCard extends StatelessWidget {
  final Content content;
  final VoidCallback onTap;

  const _ContentGridCard({required this.content, required this.onTap});

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
                              Container(color: AppColors.surface),
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
        ],
      ),
    );
  }
}