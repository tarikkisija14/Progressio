import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:progressio_mobile/model/notification_item.dart';
import 'package:progressio_mobile/providers/notification_provider.dart';
import 'package:progressio_mobile/providers/user_list_provider.dart';
import 'package:progressio_mobile/screens/content_detail_screen.dart';
import 'package:progressio_mobile/screens/user_profile_screen.dart';
import 'package:progressio_mobile/utils/app_colors.dart';
import 'package:progressio_mobile/widgets/app_ui.dart';
import 'package:progressio_mobile/widgets/skeleton_loader.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationItem> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items =
          await context.read<NotificationProvider>().getMyNotifications();
      if (mounted) setState(() => _notifications = items);
    } catch (e) {
      debugPrint('Notifications load error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markRead(NotificationItem item) async {
    if (item.isRead) return;
    try {
      await context.read<NotificationProvider>().markRead(item.id);
      if (mounted) {
        setState(() {
          final idx = _notifications.indexWhere((n) => n.id == item.id);
          if (idx != -1) {
            _notifications[idx] = NotificationItem(
              id: item.id,
              type: item.type,
              title: item.title,
              message: item.message,
              isRead: true,
              createdAt: item.createdAt,
              relatedEntityId: item.relatedEntityId,
            );
          }
        });
      }
    } catch (e) {
      debugPrint('Mark read error: $e');
    }
  }

  /// Navigira na odgovarajući screen ovisno o tipu notifikacije i relatedEntityId.
  void _handleTap(NotificationItem item) {
    _markRead(item);

    final entityId = item.relatedEntityId;
    if (entityId == null) return;

    final type = item.type.toLowerCase();

    if (type == 'follow') {
      // relatedEntityId je userId koji nas je pratio
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => UserProfileScreen(userId: entityId),
        ),
      );
    } else if (type == 'achievement') {
      // Achievement notifikacije nemaju specifičan entity screen — samo mark read
    } else if (type == 'listinvite') {
      // relatedEntityId je listId — prikaži dijalog za prihvatanje/odbijanje pozivnice
      _showListInviteDialog(item, entityId);
    } else {
      // 'episode', 'comment' i sve ostalo:
      // relatedEntityId je contentId
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ContentDetailScreen(contentId: entityId),
        ),
      );
    }
  }

  Future<void> _showListInviteDialog(NotificationItem item, int listId) async {
    final action = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'List Invitation',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        content: Text(
          item.message.isNotEmpty
              ? item.message
              : 'You have been invited to a shared list.',
          style: const TextStyle(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop('decline'),
            child: const Text('Decline',
                style: TextStyle(color: AppColors.error)),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop('accept'),
            child: const Text('Accept'),
          ),
        ],
      ),
    );

    if (action == null || !mounted) return;

    try {
      final provider = context.read<UserListProvider>();
      if (action == 'accept') {
        await provider.acceptInvite(listId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invite accepted. The list was added to your lists.'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        await provider.declineInvite(listId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invite declined.'),
              backgroundColor: AppColors.surface,
            ),
          );
        }
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          if (_notifications.any((n) => !n.isRead))
            TextButton(
              onPressed: _markAllRead,
              child: const Text(
                'Mark all read',
                style: TextStyle(color: AppColors.primary, fontSize: 13),
              ),
            ),
        ],
      ),
      body: AppShellBackground(
        child: RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.card,
          onRefresh: _load,
          child: _loading
              ? _buildSkeleton()
              : _notifications.isEmpty
                  ? _buildEmpty()
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                      itemCount: _notifications.length,
                      separatorBuilder: (_, __) =>
                          const Divider(color: AppColors.hairline, height: 1),
                      itemBuilder: (_, i) => _NotificationTile(
                        item: _notifications[i],
                        onTap: () => _handleTap(_notifications[i]),
                      ),
                    ),
        ),
      ),
    );
  }

  Future<void> _markAllRead() async {
    final unread = _notifications.where((n) => !n.isRead).toList();
    for (final item in unread) {
      await _markRead(item);
    }
  }

  Widget _buildSkeleton() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      itemCount: 6,
      separatorBuilder: (_, __) =>
          const Divider(color: AppColors.hairline, height: 1),
      itemBuilder: (_, __) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            SkeletonBox(width: 40, height: 40, radius: 20),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 200, height: 13),
                  SizedBox(height: 6),
                  SkeletonBox(width: 140, height: 11),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.notifications_none_rounded,
              color: AppColors.textFaint, size: 52),
          SizedBox(height: 14),
          Text(
            'No notifications yet.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationItem item;
  final VoidCallback onTap;

  const _NotificationTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIcon(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight:
                          item.isRead ? FontWeight.w500 : FontWeight.w700,
                    ),
                  ),
                  if (item.message.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      item.message,
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        _timeAgo(item.createdAt),
                        style: const TextStyle(
                            color: AppColors.textFaint, fontSize: 11),
                      ),
                      if (_isNavigable) ...[
                        const SizedBox(width: 6),
                        const Text(
                          'Tap to open →',
                          style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (!item.isRead)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4, left: 8),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool get _isNavigable {
    if (item.relatedEntityId == null) return false;
    final t = item.type.toLowerCase();
    return t == 'follow' || t == 'episode' || t == 'comment' ||
        t == 'listinvite';
  }

  Widget _buildIcon() {
    IconData icon;
    Color color;
    switch (item.type.toLowerCase()) {
      case 'achievement':
        icon = Icons.emoji_events_rounded;
        color = AppColors.premium;
        break;
      case 'follow':
        icon = Icons.person_add_rounded;
        color = AppColors.info;
        break;
      case 'comment':
        icon = Icons.comment_rounded;
        color = AppColors.secondary;
        break;
      case 'episode':
        icon = Icons.play_circle_rounded;
        color = AppColors.primary;
        break;
      case 'listinvite':
        icon = Icons.list_alt_rounded;
        color = AppColors.success;
        break;
      default:
        icon = Icons.notifications_rounded;
        color = AppColors.textMuted;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 20),
    );
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