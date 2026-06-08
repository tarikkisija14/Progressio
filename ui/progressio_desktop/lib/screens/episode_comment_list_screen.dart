import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:progressio_desktop/layouts/master_screen.dart';
import 'package:progressio_desktop/model/comment.dart';
import 'package:progressio_desktop/model/content.dart';
import 'package:progressio_desktop/providers/comment_provider.dart';
import 'package:progressio_desktop/providers/content_provider.dart';
import 'package:progressio_desktop/utils/app_colors.dart';
import 'package:progressio_desktop/utils/utils.dart';

class EpisodeCommentListScreen extends StatefulWidget {
  const EpisodeCommentListScreen({super.key});

  @override
  State<EpisodeCommentListScreen> createState() =>
      _EpisodeCommentListScreenState();
}

class _EpisodeCommentListScreenState extends State<EpisodeCommentListScreen> {
  late CommentProvider _commentProvider;
  late ContentProvider _contentProvider;

  final _contentSearchController = TextEditingController();

  List<Content> _contents = [];
  Content? _selectedContent;
  List<Comment> _comments = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _commentProvider = context.read<CommentProvider>();
      _contentProvider = context.read<ContentProvider>();
      _loadContents();
    });
  }

  @override
  void dispose() {
    _contentSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadContents() async {
    try {
      final result = await _contentProvider.get(filter: {'pageSize': 200});
      setState(() => _contents = result.items ?? []);
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _loadComments() async {
    if (_selectedContent == null) return;
    setState(() => _loading = true);
    try {
      final comments = await _commentProvider.getByContent(
        _selectedContent!.id,
        pageSize: 100,
      );
      setState(() => _comments = comments);
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _deleteComment(Comment comment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Delete Comment',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'Are you sure you want to delete this comment?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _commentProvider.delete(comment.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Comment deleted.'),
            backgroundColor: AppColors.error),
      );
      _loadComments();
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MasterScreen(
      title: 'Comment Moderation',
      child: Row(
        children: [
          // Left — content picker
          Container(
            width: 280,
            color: AppColors.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SELECT CONTENT',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _contentSearchController,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          hintText: 'Search content...',
                          prefixIcon: Icon(Icons.search,
                              color: AppColors.textMuted, size: 18),
                          isDense: true,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.divider),
                Expanded(
                  child: ListView(
                    children: _contents
                        .where((c) =>
                            _contentSearchController.text.isEmpty ||
                            c.title.toLowerCase().contains(
                                _contentSearchController.text.toLowerCase()))
                        .map((c) => ListTile(
                              dense: true,
                              selected: _selectedContent?.id == c.id,
                              selectedTileColor:
                                  AppColors.primary.withOpacity(0.15),
                              title: Text(
                                c.title,
                                style: TextStyle(
                                  color: _selectedContent?.id == c.id
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                c.contentTypeName ?? '',
                                style: const TextStyle(
                                    color: AppColors.textMuted, fontSize: 11),
                              ),
                              onTap: () {
                                setState(() => _selectedContent = c);
                                _loadComments();
                              },
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 1, color: AppColors.divider),
          // Right — comments
          Expanded(
            child: Column(
              children: [
                _buildToolbar(),
                const Divider(height: 1, color: AppColors.divider),
                Expanded(child: _buildContent()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Text(
            _selectedContent != null
                ? 'Comments — ${_selectedContent!.title} (${_comments.length})'
                : 'Select a content to view comments',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          if (_selectedContent != null)
            IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
              tooltip: 'Refresh',
              onPressed: _loadComments,
            ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_selectedContent == null) {
      return const Center(
        child: Text('Select a content from the left panel.',
            style: TextStyle(color: AppColors.textMuted)),
      );
    }
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_comments.isEmpty) {
      return const Center(
        child: Text('No comments found.',
            style: TextStyle(color: AppColors.textMuted)),
      );
    }
    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('User')),
            DataColumn(label: Text('Comment')),
            DataColumn(label: Text('Flags')),
            DataColumn(label: Text('Likes')),
            DataColumn(label: Text('Date')),
            DataColumn(label: Text('')),
          ],
          rows: _comments.map((c) => _buildRow(c)).toList(),
        ),
      ),
    );
  }

  DataRow _buildRow(Comment c) {
    return DataRow(
      color: WidgetStatePropertyAll(
        c.isDeleted
            ? AppColors.error.withOpacity(0.05)
            : AppColors.surface,
      ),
      cells: [
        DataCell(Text(c.username ?? 'Unknown',
            style: const TextStyle(color: AppColors.textPrimary))),
        DataCell(
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Text(
              c.content,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              style: TextStyle(
                color: c.isDeleted
                    ? AppColors.textMuted
                    : AppColors.textSecondary,
                decoration:
                    c.isDeleted ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
        ),
        DataCell(
          Row(
            children: [
              if (c.isSpoiler) _badge('Spoiler', AppColors.warning),
              if (!c.isVisible) ...[
                const SizedBox(width: 4),
                _badge('Hidden', AppColors.error),
              ],
              if (c.isDeleted) ...[
                const SizedBox(width: 4),
                _badge('Deleted', AppColors.error),
              ],
            ],
          ),
        ),
        DataCell(Text('${c.likesCount}',
            style: const TextStyle(color: AppColors.textMuted))),
        DataCell(Text(formatDateTime(c.createdAt),
            style: const TextStyle(
                color: AppColors.textMuted, fontSize: 12))),
        DataCell(
          c.isDeleted
              ? const SizedBox.shrink()
              : IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: AppColors.error, size: 18),
                  tooltip: 'Delete comment',
                  onPressed: () => _deleteComment(c),
                ),
        ),
      ],
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11)),
    );
  }
}