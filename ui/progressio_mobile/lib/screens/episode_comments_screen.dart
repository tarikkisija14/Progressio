import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:progressio_mobile/model/comment.dart';
import 'package:progressio_mobile/providers/comment_provider.dart';
import 'package:progressio_mobile/utils/app_colors.dart';
import 'package:progressio_mobile/widgets/skeleton_loader.dart';

class EpisodeCommentsScreen extends StatefulWidget {
  final int episodeId;
  final String episodeTitle;

  const EpisodeCommentsScreen({
    super.key,
    required this.episodeId,
    required this.episodeTitle,
  });

  @override
  State<EpisodeCommentsScreen> createState() => _EpisodeCommentsScreenState();
}

class _EpisodeCommentsScreenState extends State<EpisodeCommentsScreen> {
  List<Comment> _comments = [];
  bool _loading = true;
  bool _hideSpoilers = true;
  final Set<int> _revealedSpoilers = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await context
          .read<CommentProvider>()
          .getEpisodeComments(widget.episodeId, hideSpoilers: false);
      if (mounted) {
        setState(() {
          _comments = items;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showAddComment() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _AddCommentSheet(
        episodeId: widget.episodeId,
        provider: context.read<CommentProvider>(),
        onPosted: _load,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Comments',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700)),
            Text(widget.episodeTitle,
                style: const TextStyle(color: AppColors.textFaint, fontSize: 11)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              children: [
                const Text('Spoilers',
                    style: TextStyle(color: AppColors.textFaint, fontSize: 12)),
                Switch(
                  value: !_hideSpoilers,
                  onChanged: (v) => setState(() {
                    _hideSpoilers = !v;
                    if (_hideSpoilers) _revealedSpoilers.clear();
                  }),
                  activeColor: AppColors.primary,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
          ),
        ],
      ),
      body: _loading
          ? _buildSkeleton()
          : RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.card,
              onRefresh: _load,
              child: _comments.isEmpty
                  ? _buildEmpty()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                      itemCount: _comments.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) => _CommentCard(
                        comment: _comments[i],
                        hideSpoilers: _hideSpoilers,
                        isRevealed: _revealedSpoilers.contains(_comments[i].id),
                        onReveal: () => setState(
                            () => _revealedSpoilers.add(_comments[i].id)),
                        onLike: () => _toggleLike(_comments[i]),
                      ),
                    ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddComment,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add_comment_rounded),
        label: const Text('Add Comment',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  Future<void> _toggleLike(Comment comment) async {
    try {
      await context.read<CommentProvider>().toggleLike(comment.id);
      _load();
    } catch (_) {}
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.chat_bubble_outline_rounded,
              color: AppColors.textFaint, size: 52),
          SizedBox(height: 16),
          Text('No comments yet',
              style: TextStyle(color: AppColors.textMuted, fontSize: 16)),
          SizedBox(height: 6),
          Text('Be the first to comment',
              style: TextStyle(color: AppColors.textFaint, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, __) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(width: 36, height: 36, radius: 18),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 100, height: 12),
                  SizedBox(height: 8),
                  SkeletonBox(width: double.infinity, height: 12),
                  SizedBox(height: 4),
                  SkeletonBox(width: 200, height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── CommentCard ───────────────────────────────────────────────────────────────

class _CommentCard extends StatelessWidget {
  final Comment comment;
  final bool hideSpoilers;
  final bool isRevealed;
  final VoidCallback onReveal;
  final VoidCallback onLike;

  const _CommentCard({
    required this.comment,
    required this.hideSpoilers,
    required this.isRevealed,
    required this.onReveal,
    required this.onLike,
  });

  bool get _shouldMask => comment.isSpoiler && hideSpoilers && !isRevealed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 10),
          _buildBody(),
          const SizedBox(height: 10),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.surface,
          child: Text(
            comment.username != null && comment.username!.isNotEmpty
                ? comment.username![0].toUpperCase()
                : '?',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(comment.username ?? 'User',
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              Text(_formatTime(comment.createdAt),
                  style: const TextStyle(
                      color: AppColors.textFaint, fontSize: 11)),
            ],
          ),
        ),
        if (comment.isSpoiler)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6)),
            child: const Text('SPOILER',
                style: TextStyle(
                    color: AppColors.warning,
                    fontSize: 10,
                    fontWeight: FontWeight.w700)),
          ),
      ],
    );
  }

  Widget _buildBody() {
    if (_shouldMask) {
      return GestureDetector(
        onTap: onReveal,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.warning.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.warning.withOpacity(0.3)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.visibility_off_rounded,
                  color: AppColors.warning, size: 16),
              SizedBox(width: 8),
              Text('Tap to reveal spoiler',
                  style: TextStyle(
                      color: AppColors.warning,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
    }
    return Text(
      comment.content,
      style: const TextStyle(
          color: AppColors.textSecondary, fontSize: 13, height: 1.5),
    );
  }

  Widget _buildFooter() {
    return Row(
      children: [
        InkWell(
          onTap: onLike,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              children: [
                const Icon(Icons.favorite_border_rounded,
                    color: AppColors.textFaint, size: 16),
                const SizedBox(width: 4),
                Text('${comment.likesCount}',
                    style: const TextStyle(
                        color: AppColors.textFaint, fontSize: 12)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 30) return '${diff.inDays}d ago';
    return '${dt.day}.${dt.month}.${dt.year}';
  }
}

// ── AddCommentSheet ───────────────────────────────────────────────────────────

class _AddCommentSheet extends StatefulWidget {
  final int episodeId;
  final CommentProvider provider;
  final VoidCallback onPosted;

  const _AddCommentSheet({
    required this.episodeId,
    required this.provider,
    required this.onPosted,
  });

  @override
  State<_AddCommentSheet> createState() => _AddCommentSheetState();
}

class _AddCommentSheetState extends State<_AddCommentSheet> {
  final _ctrl = TextEditingController();
  bool _hasSpoiler = false;
  bool _posting = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _post() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || text.length > 500) return;
    setState(() => _posting = true);
    try {
      await widget.provider.addEpisodeComment(
        widget.episodeId,
        text: text,
        hasSpoiler: _hasSpoiler,
      );
      widget.onPosted();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _posting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Add Comment',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => TextField(
              controller: _ctrl,
              maxLength: 500,
              maxLines: 4,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Write your comment…',
                counterStyle: TextStyle(
                  color: _ctrl.text.length > 480
                      ? AppColors.error
                      : AppColors.textFaint,
                  fontSize: 11,
                ),
              ),
            ),
          ),
          SwitchListTile(
            value: _hasSpoiler,
            onChanged: (v) => setState(() => _hasSpoiler = v),
            title: const Text('Contains spoiler',
                style:
                    TextStyle(color: AppColors.textPrimary, fontSize: 14)),
            activeColor: AppColors.warning,
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed:
                  _posting || _ctrl.text.trim().isEmpty ? null : _post,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _posting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.black))
                  : const Text('Post Comment',
                      style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}