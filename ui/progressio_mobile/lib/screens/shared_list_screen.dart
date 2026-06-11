import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:progressio_mobile/model/user_list.dart';
import 'package:progressio_mobile/providers/auth_provider.dart';
import 'package:progressio_mobile/providers/user_list_provider.dart';
import 'package:progressio_mobile/screens/content_detail_screen.dart';
import 'package:progressio_mobile/utils/app_colors.dart';
import 'package:progressio_mobile/widgets/skeleton_loader.dart';

class SharedListScreen extends StatefulWidget {
  final UserList list;
  const SharedListScreen({super.key, required this.list});

  @override
  State<SharedListScreen> createState() => _SharedListScreenState();
}

class _SharedListScreenState extends State<SharedListScreen> {
  List<UserListItem> _items = [];
  List<UserListMember> _members = [];
  bool _loadingItems = true;
  bool _loadingMembers = false;
  bool _isOwner = false;

  @override
  void initState() {
    super.initState();
    _isOwner = (AuthProvider.currentUserId != null &&
        AuthProvider.currentUserId == widget.list.userId);
    _loadItems();
    if (widget.list.isShared) _loadMembers();
  }

  Future<void> _loadItems() async {
    setState(() => _loadingItems = true);
    try {
      final items = await context.read<UserListProvider>().getListItems(widget.list.id);
      if (mounted) setState(() {
        _items = items;
        _loadingItems = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingItems = false);
    }
  }

  Future<void> _loadMembers() async {
    setState(() => _loadingMembers = true);
    try {
      final members = await context.read<UserListProvider>().getMembers(widget.list.id);
      if (mounted) setState(() {
        _members = members;
        _loadingMembers = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingMembers = false);
    }
  }

  Future<void> _removeItem(UserListItem item) async {
    try {
      await context.read<UserListProvider>().removeContent(widget.list.id, item.contentId);
      setState(() => _items.removeWhere((e) => e.id == item.id));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          if (widget.list.isShared) SliverToBoxAdapter(child: _buildMembersSection()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
              child: Text(
                '${_items.length} item${_items.length != 1 ? 's' : ''}',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            ),
          ),
          if (_loadingItems)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, __) => const Padding(
                  padding: EdgeInsets.fromLTRB(18, 0, 18, 10),
                  child: SkeletonBox(width: double.infinity, height: 72),
                ),
                childCount: 5,
              ),
            )
          else if (_items.isEmpty)
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(48),
                  child: Column(
                    children: const [
                      Icon(Icons.playlist_add_rounded, color: AppColors.textFaint, size: 52),
                      SizedBox(height: 14),
                      Text('No items in this list',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 15)),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 32),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _buildItemTile(_items[i]),
                  childCount: _items.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      pinned: true,
      title: Text(widget.list.name,
          style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700)),
      actions: [
        if (_isOwner && widget.list.isShared)
          IconButton(
            icon: const Icon(Icons.person_add_rounded, color: AppColors.primary),
            onPressed: _showInviteSheet,
            tooltip: 'Invite user',
          ),
      ],
    );
  }

  Widget _buildMembersSection() {
    if (_loadingMembers) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(18, 12, 18, 0),
        child: SkeletonBox(width: double.infinity, height: 56),
      );
    }
    if (_members.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Members',
              style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _members.map(_buildMemberChip).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberChip(UserListMember m) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: m.canEdit ? AppColors.primary.withOpacity(0.4) : AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: AppColors.surface,
            backgroundImage: m.profileImageUrl != null
                ? CachedNetworkImageProvider(m.profileImageUrl!)
                : null,
            child: m.profileImageUrl == null
                ? Text(m.username.isNotEmpty ? m.username[0].toUpperCase() : '?',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 11))
                : null,
          ),
          const SizedBox(width: 6),
          Text(m.username,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
          if (m.canEdit) ...[
            const SizedBox(width: 4),
            const Icon(Icons.edit_rounded, color: AppColors.primary, size: 12),
          ],
        ],
      ),
    );
  }

  Widget _buildItemTile(UserListItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => ContentDetailScreen(contentId: item.contentId)),
        ),
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
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 44,
                  height: 66,
                  child: item.contentCoverImageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: item.contentCoverImageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(color: AppColors.surface),
                          errorWidget: (_, __, ___) =>
                              Container(color: AppColors.surface),
                        )
                      : Container(
                          color: AppColors.surface,
                          child: const Icon(Icons.movie_rounded,
                              color: AppColors.textFaint, size: 18)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.contentTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(item.contentTypeName,
                        style: const TextStyle(
                            color: AppColors.textFaint, fontSize: 12)),
                    if (item.note != null && item.note!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(item.note!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                              fontStyle: FontStyle.italic)),
                    ],
                  ],
                ),
              ),
              if (_isOwner || widget.list.isShared)
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline_rounded,
                      color: AppColors.textFaint, size: 20),
                  onPressed: () => _removeItem(item),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showInviteSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _InviteSheet(
        listId: widget.list.id,
        provider: context.read<UserListProvider>(),
      ),
    );
  }
}

class _InviteSheet extends StatefulWidget {
  final int listId;
  final UserListProvider provider;
  const _InviteSheet({required this.listId, required this.provider});

  @override
  State<_InviteSheet> createState() => _InviteSheetState();
}

class _InviteSheetState extends State<_InviteSheet> {
  final _ctrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _invite() async {
    final idStr = _ctrl.text.trim();
    final userId = int.tryParse(idStr);
    if (userId == null) return;
    setState(() => _sending = true);
    try {
      await widget.provider.inviteUser(widget.listId, userId);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Invite sent'),
              backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _sending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(width: 36, height: 4,
                decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 16),
          const Text('Invite User',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          TextField(
            controller: _ctrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              labelText: 'User ID',
              hintText: 'Enter user ID to invite',
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _sending ? null : _invite,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _sending
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Text('Send Invite',
                      style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}