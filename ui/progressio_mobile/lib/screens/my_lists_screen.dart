import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:progressio_mobile/model/user_list.dart';
import 'package:progressio_mobile/providers/auth_provider.dart';
import 'package:progressio_mobile/providers/user_list_provider.dart';
import 'package:progressio_mobile/screens/shared_list_screen.dart';
import 'package:progressio_mobile/utils/app_colors.dart';
import 'package:progressio_mobile/widgets/app_ui.dart';
import 'package:progressio_mobile/widgets/skeleton_loader.dart';

class MyListsScreen extends StatefulWidget {
  const MyListsScreen({super.key});

  @override
  State<MyListsScreen> createState() => _MyListsScreenState();
}

class _MyListsScreenState extends State<MyListsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<UserList> _myLists = [];
  List<UserList> _publicLists = [];
  bool _loadingMine = true;
  bool _loadingPublic = false;
  final _publicSearchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() {
      if (_tabCtrl.index == 1 && _publicLists.isEmpty && !_loadingPublic) {
        _loadPublic();
      }
    });
    _loadMine();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _publicSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMine() async {
    setState(() => _loadingMine = true);
    try {
      final lists = await context.read<UserListProvider>().getMyLists();
      if (mounted) setState(() {
        _myLists = lists;
        _loadingMine = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingMine = false);
    }
  }

  Future<void> _loadPublic({String? search}) async {
    setState(() => _loadingPublic = true);
    try {
      final lists = await context.read<UserListProvider>().getPublicLists(search: search);
      if (mounted) setState(() {
        _publicLists = lists;
        _loadingPublic = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingPublic = false);
    }
  }

  Future<void> _createList() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _CreateListSheet(provider: context.read<UserListProvider>()),
    );
    if (result == true) _loadMine();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppShellBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildTabs(),
              Expanded(
                child: TabBarView(
                  controller: _tabCtrl,
                  children: [
                    _buildMyLists(),
                    _buildPublicLists(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createList,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.black,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(18, 20, 18, 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'My Lists',
          style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 8, 18, 0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabCtrl,
        indicator: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.black,
        unselectedLabelColor: AppColors.textMuted,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'My Lists'),
          Tab(text: 'Discover'),
        ],
      ),
    );
  }

  Widget _buildMyLists() {
    if (_loadingMine) {
      return ListView.separated(
        padding: const EdgeInsets.all(18),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, __) => const SkeletonBox(width: double.infinity, height: 76),
      );
    }
    if (_myLists.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.list_rounded, color: AppColors.textFaint, size: 52),
            const SizedBox(height: 14),
            const Text('No lists yet', style: TextStyle(color: AppColors.textMuted, fontSize: 16)),
            const SizedBox(height: 6),
            const Text('Tap + to create your first list',
                style: TextStyle(color: AppColors.textFaint, fontSize: 13)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.card,
      onRefresh: _loadMine,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 88),
        itemCount: _myLists.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) => _ListCard(
          list: _myLists[i],
          isOwn: true,
          onTap: () => _openList(_myLists[i]),
          onDelete: () => _deleteList(_myLists[i]),
        ),
      ),
    );
  }

  Widget _buildPublicLists() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
          child: TextField(
            controller: _publicSearchCtrl,
            textInputAction: TextInputAction.search,
            onSubmitted: (v) => _loadPublic(search: v),
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Search public lists…',
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textFaint),
              suffixIcon: IconButton(
                icon: const Icon(Icons.search_rounded, color: AppColors.primary),
                onPressed: () => _loadPublic(search: _publicSearchCtrl.text),
              ),
            ),
          ),
        ),
        Expanded(
          child: _loadingPublic
              ? ListView.separated(
                  padding: const EdgeInsets.all(18),
                  itemCount: 5,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, __) => const SkeletonBox(width: double.infinity, height: 76),
                )
              : _publicLists.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.explore_rounded, color: AppColors.textFaint, size: 52),
                          const SizedBox(height: 14),
                          const Text('Search for public lists',
                              style: TextStyle(color: AppColors.textMuted, fontSize: 15)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(18, 12, 18, 88),
                      itemCount: _publicLists.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) => _ListCard(
                        list: _publicLists[i],
                        isOwn: false,
                        onTap: () => _openList(_publicLists[i]),
                        onFork: () => _forkList(_publicLists[i]),
                      ),
                    ),
        ),
      ],
    );
  }

  void _openList(UserList list) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SharedListScreen(list: list)),
    ).then((_) => _loadMine());
  }

  Future<void> _deleteList(UserList list) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete list', style: TextStyle(color: AppColors.textPrimary)),
        content: Text('Delete "${list.name}"?',
            style: const TextStyle(color: AppColors.textMuted)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await context.read<UserListProvider>().deleteList(list.id);
        _loadMine();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  Future<void> _forkList(UserList list) async {
    try {
      await context.read<UserListProvider>().forkList(list.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Forked "${list.name}" to your lists'),
            backgroundColor: AppColors.success,
          ),
        );
      }
      _loadMine();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }
}

// ── ListCard ─────────────────────────────────────────────────────────────────

class _ListCard extends StatelessWidget {
  final UserList list;
  final bool isOwn;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onFork;

  const _ListCard({
    required this.list,
    required this.isOwn,
    required this.onTap,
    this.onDelete,
    this.onFork,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _iconBg(),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_icon(), color: _iconColor(), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(list.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _badge(_badgeLabel(), _badgeBg(), _badgeFg()),
                      const SizedBox(width: 8),
                      Text('${list.itemCount} items',
                          style: const TextStyle(
                              color: AppColors.textFaint, fontSize: 12)),
                      if (list.memberCount > 0 && list.isShared) ...[
                        const SizedBox(width: 8),
                        Text('${list.memberCount} members',
                            style: const TextStyle(
                                color: AppColors.textFaint, fontSize: 12)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (!isOwn && onFork != null)
              IconButton(
                icon: const Icon(Icons.fork_right_rounded,
                    color: AppColors.primary, size: 20),
                onPressed: onFork,
                tooltip: 'Fork list',
              )
            else if (isOwn && onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.textFaint, size: 20),
                onPressed: onDelete,
              ),
          ],
        ),
      ),
    );
  }

  IconData _icon() {
    if (list.isShared) return Icons.group_rounded;
    if (list.isPublic) return Icons.public_rounded;
    return Icons.lock_rounded;
  }

  Color _iconBg() {
    if (list.isShared) return AppColors.primarySoft;
    if (list.isPublic) return AppColors.info.withOpacity(0.15);
    return AppColors.surface;
  }

  Color _iconColor() {
    if (list.isShared) return AppColors.primary;
    if (list.isPublic) return AppColors.info;
    return AppColors.textMuted;
  }

  String _badgeLabel() {
    if (list.isShared) return 'Shared';
    if (list.isPublic) return 'Public';
    return 'Private';
  }

  Color _badgeBg() {
    if (list.isShared) return AppColors.primarySoft;
    if (list.isPublic) return AppColors.info.withOpacity(0.15);
    return AppColors.surface;
  }

  Color _badgeFg() {
    if (list.isShared) return AppColors.primary;
    if (list.isPublic) return AppColors.info;
    return AppColors.textFaint;
  }

  Widget _badge(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

// ── CreateListSheet ───────────────────────────────────────────────────────────

class _CreateListSheet extends StatefulWidget {
  final UserListProvider provider;
  const _CreateListSheet({required this.provider});

  @override
  State<_CreateListSheet> createState() => _CreateListSheetState();
}

class _CreateListSheetState extends State<_CreateListSheet> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _isPublic = false;
  bool _isShared = false;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await widget.provider.createList(
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        isPublic: _isPublic,
        isShared: _isShared,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
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
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.border, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Create List',
              style: TextStyle(
                  color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          TextField(
            controller: _nameCtrl,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(labelText: 'List name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descCtrl,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(labelText: 'Description (optional)'),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            value: _isPublic,
            onChanged: (v) => setState(() => _isPublic = v),
            title: const Text('Public', style: TextStyle(color: AppColors.textPrimary)),
            subtitle: const Text('Anyone can see and fork this list',
                style: TextStyle(color: AppColors.textFaint, fontSize: 12)),
            activeColor: AppColors.primary,
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            value: _isShared,
            onChanged: (v) => setState(() => _isShared = v),
            title: const Text('Shared', style: TextStyle(color: AppColors.textPrimary)),
            subtitle: const Text('Invite others to collaborate',
                style: TextStyle(color: AppColors.textFaint, fontSize: 12)),
            activeColor: AppColors.primary,
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _saving
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Text('Create List', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}