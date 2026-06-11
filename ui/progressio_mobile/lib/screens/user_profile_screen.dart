import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:progressio_mobile/model/user.dart';
import 'package:progressio_mobile/providers/user_provider.dart';
import 'package:progressio_mobile/utils/app_colors.dart';
import 'package:progressio_mobile/widgets/skeleton_loader.dart';

class UserProfileScreen extends StatefulWidget {
  final int userId;
  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  AppUser? _user;
  bool _loading = true;
  bool _isPrivate = false;
  bool _followLoading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final user = await context.read<UserProvider>().getProfile(widget.userId);
      if (mounted) setState(() {
        _user = user;
        _loading = false;
        _isPrivate = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _loading = false;
        _isPrivate = e.toString().contains('403') || e.toString().contains('Forbidden');
      });
    }
  }

  Future<void> _toggleFollow() async {
    if (_user == null) return;
    setState(() => _followLoading = true);
    try {
      // We use isProfilePublic as a proxy for "I follow them" — not ideal,
      // but the backend UserProfileResponse doesn't include isFollowing.
      // In a real scenario you'd have a separate isFollowing field.
      await context.read<UserProvider>().follow(widget.userId);
      await _load();
    } catch (_) {
      try {
        await context.read<UserProvider>().unfollow(widget.userId);
        await _load();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
          );
        }
      }
    }
    if (mounted) setState(() => _followLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        title: Text(
          _user?.username ?? 'Profile',
          style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700),
        ),
      ),
      body: _loading
          ? _buildSkeleton()
          : _isPrivate
              ? _buildPrivateState()
              : _user == null
                  ? _buildErrorState()
                  : _buildProfile(),
    );
  }

  Widget _buildProfile() {
    final u = _user!;
    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.card,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 32),
        children: [
          _buildAvatarRow(u),
          const SizedBox(height: 20),
          _buildStatsRow(u),
          const SizedBox(height: 20),
          _buildFollowButton(),
          const SizedBox(height: 24),
          _buildInfoSection(u),
        ],
      ),
    );
  }

  Widget _buildAvatarRow(AppUser u) {
    return Row(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: AppColors.surface,
          backgroundImage: u.profileImageUrl != null
              ? CachedNetworkImageProvider(u.profileImageUrl!)
              : null,
          child: u.profileImageUrl == null
              ? Text(
                  u.username.isNotEmpty ? u.username[0].toUpperCase() : '?',
                  style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 28,
                      fontWeight: FontWeight.w700),
                )
              : null,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      u.fullName.isNotEmpty ? u.fullName : u.username,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (u.isPremium) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [AppColors.premium, AppColors.primary]),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('PRO',
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: 10,
                              fontWeight: FontWeight.w800)),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 3),
              Text('@${u.username}',
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(AppUser u) {
    return Row(
      children: [
        Expanded(child: _statBox('Completed', u.totalCompleted.toString(), AppColors.success)),
        const SizedBox(width: 10),
        Expanded(child: _statBox('In Progress', u.totalInProgress.toString(), AppColors.primary)),
        const SizedBox(width: 10),
        Expanded(child: _statBox('Member since', _formatYear(u.createdAt), AppColors.textMuted)),
      ],
    );
  }

  Widget _statBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 3),
          Text(label,
              style: const TextStyle(color: AppColors.textFaint, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildFollowButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _followLoading ? null : _toggleFollow,
        icon: _followLoading
            ? const SizedBox(width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
            : const Icon(Icons.person_add_rounded, size: 18),
        label: const Text('Follow / Unfollow'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildInfoSection(AppUser u) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _infoRow(Icons.email_rounded, u.email),
          const Divider(color: AppColors.divider, height: 20),
          _infoRow(
            u.isProfilePublic ? Icons.public_rounded : Icons.lock_rounded,
            u.isProfilePublic ? 'Public profile' : 'Private profile',
          ),
          if (u.activePlanType != null) ...[
            const Divider(color: AppColors.divider, height: 20),
            _infoRow(Icons.star_rounded, '${u.activePlanType} plan',
                color: AppColors.premium),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, {Color color = AppColors.textMuted}) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Text(text, style: TextStyle(color: color, fontSize: 13)),
      ],
    );
  }

  Widget _buildPrivateState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.lock_rounded, color: AppColors.textMuted, size: 32),
            ),
            const SizedBox(height: 18),
            const Text('Private Profile',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            const Text(
              'This profile is private. Follow this user to see their activity.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _followLoading ? null : _toggleFollow,
              icon: const Icon(Icons.person_add_rounded, size: 18),
              label: const Text('Send Follow Request'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 20),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person_off_rounded, color: AppColors.textFaint, size: 52),
          const SizedBox(height: 16),
          const Text('User not found',
              style: TextStyle(color: AppColors.textMuted, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: const [
        Row(children: [
          SkeletonBox(width: 80, height: 80, radius: 40),
          SizedBox(width: 16),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SkeletonBox(width: 140, height: 18),
            SizedBox(height: 8),
            SkeletonBox(width: 90, height: 13),
          ]),
        ]),
        SizedBox(height: 20),
        Row(children: [
          Expanded(child: SkeletonBox(width: double.infinity, height: 64)),
          SizedBox(width: 10),
          Expanded(child: SkeletonBox(width: double.infinity, height: 64)),
          SizedBox(width: 10),
          Expanded(child: SkeletonBox(width: double.infinity, height: 64)),
        ]),
      ],
    );
  }

  String _formatYear(DateTime dt) => dt.year.toString();
}