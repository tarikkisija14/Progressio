import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:progressio_mobile/model/feed_item.dart';
import 'package:progressio_mobile/providers/feed_provider.dart';
import 'package:progressio_mobile/providers/user_provider.dart';
import 'package:progressio_mobile/utils/app_colors.dart';
import 'package:progressio_mobile/widgets/app_ui.dart';
import 'package:progressio_mobile/widgets/skeleton_loader.dart';

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  List<FeedItem> _feed = [];
  bool _loading = false;
  bool _loadingMore = false;
  int _page = 1;
  bool _hasMore = true;

  // User search by userId (direct lookup — no username search endpoint exists)
  int? _searchUserId;
  String _searchInput = '';
  bool _searchingUser = false;
  Map<String, dynamic>? _foundUser;
  bool _followingInProgress = false;

  @override
  void initState() {
    super.initState();
    _loadFeed();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_loadingMore &&
        _hasMore) {
      _loadMoreFeed();
    }
  }

  Future<void> _loadFeed() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _page = 1;
      _hasMore = true;
      _feed = [];
    });
    try {
      final items =
          await context.read<FeedProvider>().getFeed(page: 1);
      if (mounted) {
        setState(() {
          _feed = items;
          _hasMore = items.length >= 20;
        });
      }
    } catch (e) {
      debugPrint('Feed error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMoreFeed() async {
    if (!mounted || _loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final nextPage = _page + 1;
      final items =
          await context.read<FeedProvider>().getFeed(page: nextPage);
      if (mounted) {
        setState(() {
          _feed.addAll(items);
          _page = nextPage;
          _hasMore = items.length >= 20;
        });
      }
    } catch (e) {
      debugPrint('Feed load more error: $e');
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _searchUser() async {
    final input = _searchInput.trim();
    if (input.isEmpty) return;
    final id = int.tryParse(input);
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid user ID to search.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    setState(() {
      _searchingUser = true;
      _foundUser = null;
    });
    try {
      final profile = await context.read<UserProvider>().getProfile(id);
      if (mounted) {
        setState(() => _foundUser = {
              'id': profile.id,
              'fullName': profile.fullName,
              'username': profile.username,
              'profileImageUrl': profile.profileImageUrl,
              'isProfilePublic': profile.isProfilePublic,
              'followerCount': 0,
              'followingCount': 0,
              'isFollowing': false,
            });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User not found.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _searchingUser = false);
    }
  }

  Future<void> _toggleFollow(int userId, bool isCurrentlyFollowing) async {
    setState(() => _followingInProgress = true);
    try {
      if (isCurrentlyFollowing) {
        await context.read<UserProvider>().unfollow(userId);
      } else {
        await context.read<UserProvider>().follow(userId);
      }
      if (mounted && _foundUser != null) {
        setState(() {
          _foundUser = {
            ..._foundUser!,
            'isFollowing': !isCurrentlyFollowing,
          };
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _followingInProgress = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text(
          'Social',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: AppShellBackground(
        child: RefreshIndicator(
          onRefresh: _loadFeed,
          color: AppColors.primary,
          backgroundColor: AppColors.card,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(child: _buildSearchBar()),
              if (_foundUser != null)
                SliverToBoxAdapter(child: _buildFoundUser()),
              if (_loading)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, __) => const Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg, vertical: 6),
                      child: _SkeletonFeedCard(),
                    ),
                    childCount: 5,
                  ),
                )
              else if (_feed.isEmpty)
                SliverFillRemaining(child: _buildEmptyFeed())
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _FeedCard(item: _feed[i]),
                      ),
                      childCount: _feed.length,
                    ),
                  ),
                ),
              if (_loadingMore)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary, strokeWidth: 2),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              keyboardType: TextInputType.number,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search user by ID…',
                hintStyle: const TextStyle(color: AppColors.textFaint),
                prefixIcon: const Icon(Icons.person_search_outlined,
                    color: AppColors.textMuted),
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
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 11),
              ),
              onChanged: (v) => _searchInput = v,
              onSubmitted: (_) => _searchUser(),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _searchUser,
            child: Container(
              width: 46,
              height: 46,
              decoration: AppDecorations.brandedMark(radius: AppRadii.md),
              child: _searchingUser
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

  Widget _buildFoundUser() {
    final user = _foundUser!;
    final isFollowing = user['isFollowing'] as bool;
    return Container(
      margin: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
      padding: const EdgeInsets.all(14),
      decoration: AppDecorations.panel(borderColor: AppColors.primary),
      child: Row(
        children: [
          _buildAvatar(user['profileImageUrl'] as String?, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['fullName'] as String? ?? '',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '@${user['username']}',
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          if (!(user['isProfilePublic'] as bool))
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Private',
                  style: TextStyle(
                      color: AppColors.textMuted, fontSize: 11)),
            )
          else
            ElevatedButton(
              onPressed: _followingInProgress
                  ? null
                  : () => _toggleFollow(
                      user['id'] as int, isFollowing),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isFollowing ? AppColors.surfaceElevated : AppColors.primary,
                foregroundColor:
                    isFollowing ? AppColors.textPrimary : Colors.black,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadii.sm)),
              ),
              child: Text(
                isFollowing ? 'Unfollow' : 'Follow',
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyFeed() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.people_outline,
                color: AppColors.textFaint, size: 52),
            const SizedBox(height: 16),
            const Text(
              'Your feed is empty.\nFollow other users to see their activity.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.textMuted, fontSize: 15, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String? url, {double size = 36}) {
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: url != null && url.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    Container(color: AppColors.surface),
                errorWidget: (_, __, ___) =>
                    Container(color: AppColors.surface,
                        child: const Icon(Icons.person,
                            color: AppColors.textFaint, size: 18)),
              )
            : Container(
                color: AppColors.surface,
                child: const Icon(Icons.person,
                    color: AppColors.textFaint, size: 18)),
      ),
    );
  }
}

// ── FEED CARD ────────────────────────────────────────────────────────────────

class _FeedCard extends StatelessWidget {
  final FeedItem item;

  const _FeedCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppDecorations.panel(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatar(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 6),
                _buildBody(),
                const SizedBox(height: 6),
                _buildTimestamp(),
              ],
            ),
          ),
          if (item.contentCoverImageUrl != null)
            _buildCoverThumbnail(),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    final url = item.actorProfileImageUrl;
    return ClipOval(
      child: SizedBox(
        width: 36,
        height: 36,
        child: url != null && url.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    Container(color: AppColors.surface),
                errorWidget: (_, __, ___) =>
                    _defaultAvatar(),
              )
            : _defaultAvatar(),
      ),
    );
  }

  Widget _defaultAvatar() {
    return Container(
      color: AppColors.surface,
      child: const Icon(Icons.person, color: AppColors.textFaint, size: 18),
    );
  }

  Widget _buildHeader() {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: item.actorFullName,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextSpan(
            text: '  ${_activityVerb(item.activityType)}',
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final lines = <String>[];
    if (item.contentTitle != null) lines.add(item.contentTitle!);
    if (item.achievementName != null)
      lines.add('🏆 ${item.achievementName}');
    if (item.userListName != null) lines.add('📋 ${item.userListName}');
    if (item.reviewRating != null)
      lines.add('${'★' * item.reviewRating!} ${'☆' * (5 - item.reviewRating!)}');

    if (lines.isEmpty) return const SizedBox.shrink();

    return Text(
      lines.join(' · '),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 13,
        height: 1.4,
      ),
    );
  }

  Widget _buildTimestamp() {
    return Text(
      _timeAgo(item.occurredAt),
      style: const TextStyle(color: AppColors.textFaint, fontSize: 11),
    );
  }

  Widget _buildCoverThumbnail() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: item.contentCoverImageUrl!,
        width: 42,
        height: 60,
        fit: BoxFit.cover,
        placeholder: (_, __) =>
            Container(width: 42, height: 60, color: AppColors.surface),
        errorWidget: (_, __, ___) =>
            Container(width: 42, height: 60, color: AppColors.surface),
      ),
    );
  }

  String _activityVerb(String activityType) {
    switch (activityType.toLowerCase()) {
      case 'completion':
        return 'completed';
      case 'review':
        return 'reviewed';
      case 'achievement':
        return 'earned achievement';
      case 'listcreation':
      case 'list_creation':
        return 'created a list';
      default:
        return activityType.toLowerCase();
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// ── SKELETON ────────────────────────────────────────────────────────────────

class _SkeletonFeedCard extends StatelessWidget {
  const _SkeletonFeedCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppDecorations.panel(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox(width: 36, height: 36, radius: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SkeletonBox(width: 160, height: 13),
                SizedBox(height: 6),
                SkeletonBox(width: 220, height: 13),
                SizedBox(height: 6),
                SkeletonBox(width: 80, height: 11),
              ],
            ),
          ),
        ],
      ),
    );
  }
}