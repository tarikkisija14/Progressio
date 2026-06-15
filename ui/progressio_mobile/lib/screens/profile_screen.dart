import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:progressio_mobile/core/api_client.dart';
import 'package:provider/provider.dart';

import 'package:progressio_mobile/model/achievement.dart';
import 'package:progressio_mobile/model/stats.dart';
import 'package:progressio_mobile/model/user.dart';
import 'package:progressio_mobile/model/user_list.dart';
import 'package:progressio_mobile/providers/achievement_provider.dart';
import 'package:progressio_mobile/providers/auth_provider.dart';
import 'package:progressio_mobile/providers/stats_provider.dart';
import 'package:progressio_mobile/providers/subscription_provider.dart';
import 'package:progressio_mobile/providers/user_list_provider.dart';
import 'package:progressio_mobile/providers/user_provider.dart';
import 'package:progressio_mobile/screens/achievements_screen.dart';
import 'package:progressio_mobile/screens/change_password_screen.dart';
import 'package:progressio_mobile/screens/edit_profile_screen.dart';
import 'package:progressio_mobile/screens/login_screen.dart';
import 'package:progressio_mobile/screens/premium_screen.dart';
import 'package:progressio_mobile/screens/stats_screen.dart';
import 'package:progressio_mobile/utils/app_colors.dart';
import 'package:progressio_mobile/widgets/app_ui.dart';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:progressio_mobile/widgets/skeleton_loader.dart';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  AppUser? _user;
  BasicStats? _basicStats;
  PremiumStats? _premiumStats;
  List<dynamic> _achievements = [];
  List<UserList> _myLists = [];

  bool _loadingUser = true;
  bool _loadingStats = true;
  bool _loadingAchievements = true;
  bool _loadingLists = true;
  bool _updatingVisibility = false;
  bool _showPremiumStats = false;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    await Future.wait([
      _loadUser(),
      _loadStats(),
      _loadAchievements(),
      _loadLists(),
    ]);
  }

  Future<void> _loadUser() async {
    setState(() => _loadingUser = true);
    try {
      final user = await context.read<UserProvider>().getMe();
      if (mounted) {
        setState(() {
          _user = user;
          AuthProvider.isPremium = user.isPremium;
        });
      }
    } catch (e) {
      debugPrint('Profile load user error: $e');
    } finally {
      if (mounted) setState(() => _loadingUser = false);
    }
  }

  Future<void> _loadStats() async {
    setState(() => _loadingStats = true);
    try {
      final basic =
          await context.read<StatsProvider>().getBasicStats();
      if (mounted) setState(() => _basicStats = basic);

      if (AuthProvider.isPremium) {
        try {
          final premium =
              await context.read<StatsProvider>().getPremiumStats();
          if (mounted) setState(() => _premiumStats = premium);
        } catch (_) {
          // 403 for free users
        }
      }
    } catch (e) {
      debugPrint('Profile load stats error: $e');
    } finally {
      if (mounted) setState(() => _loadingStats = false);
    }
  }

  Future<void> _loadAchievements() async {
    setState(() => _loadingAchievements = true);
    try {
      final userId = AuthProvider.userId ?? 0;
      if (userId == 0) return;
      final data = await context
          .read<AchievementProvider>()
          .getRaw('achievements/my', query: {'page': 1, 'pageSize': 10});
      if (mounted) {
        final list = data is Map ? (data['items'] ?? []) : (data ?? []);
        setState(() => _achievements = list as List);
      }
    } catch (e) {
      debugPrint('Profile load achievements error: $e');
    } finally {
      if (mounted) setState(() => _loadingAchievements = false);
    }
  }

  Future<void> _loadLists() async {
    setState(() => _loadingLists = true);
    try {
      final lists =
          await context.read<UserListProvider>().getMyLists();
      if (mounted) setState(() => _myLists = lists);
    } catch (e) {
      debugPrint('Profile load lists error: $e');
    } finally {
      if (mounted) setState(() => _loadingLists = false);
    }
  }

  Future<void> _toggleProfileVisibility() async {
    if (_user == null || _updatingVisibility) return;
    setState(() => _updatingVisibility = true);
    try {
      await context.read<UserProvider>().putRaw(
            'auth/profile-visibility',
            {'isPublic': !_user!.isProfilePublic},
          );
      await _loadUser();
    } catch (e) {
      debugPrint('Toggle visibility error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update profile visibility.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _updatingVisibility = false);
    }
  }

  Future<void> _openEditProfile() async {
    final user = _user;
    if (user == null) return;

    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(user: user),
      ),
    );

    if (updated == true && mounted) {
      await _loadUser();
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Sign Out',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text('Are you sure you want to sign out?',
            style: TextStyle(color: AppColors.textMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final refreshToken = AuthProvider.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      AuthProvider.clear();
    } else {
      try {
        await context.read<UserProvider>().postRaw(
          'auth/logout',
          {'refreshToken': refreshToken},
        );
        AuthProvider.clear();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sign out failed: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }
    }

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppShellBackground(
        child: RefreshIndicator(
          onRefresh: _loadAll,
          color: AppColors.primary,
          backgroundColor: AppColors.card,
          child: CustomScrollView(
            slivers: [
              _buildHeader(),
              SliverToBoxAdapter(child: _buildStatsSection()),
              SliverToBoxAdapter(child: _buildAchievementsSection()),
              SliverToBoxAdapter(child: _buildQuickLinks()),
              SliverToBoxAdapter(child: _buildListsSection()),
              SliverToBoxAdapter(child: _buildLogoutSection()),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
    );
  }

  // ── HEADER ──────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          MediaQuery.of(context).padding.top + AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primarySubtle, Colors.transparent],
          ),
        ),
        child: _loadingUser ? _buildHeaderSkeleton() : _buildHeaderContent(),
      ),
    );
  }

  Widget _buildHeaderSkeleton() {
    return Column(
      children: const [
        SkeletonBox(width: 80, height: 80, radius: 40),
        SizedBox(height: 12),
        SkeletonBox(width: 140, height: 18),
        SizedBox(height: 6),
        SkeletonBox(width: 100, height: 14),
      ],
    );
  }

  Widget _buildHeaderContent() {
    if (_user == null) return const SizedBox.shrink();
    final u = _user!;

    return Column(
      children: [
        // Avatar
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            ClipOval(
              child: SizedBox(
                width: 80,
                height: 80,
                child: u.profileImageUrl != null &&
                        u.profileImageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: u.profileImageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            Container(color: AppColors.surface),
                        errorWidget: (_, __, ___) =>
                            _defaultAvatar(size: 80),
                      )
                    : _defaultAvatar(size: 80),
              ),
            ),
            if (u.isPremium)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.premium,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.star_rounded,
                    color: Colors.black, size: 12),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // Name
        Text(
          u.fullName,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '@${u.username}',
          style: const TextStyle(
              color: AppColors.textMuted, fontSize: 14),
        ),
        if (u.isPremium) ...[
          const SizedBox(height: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.premium.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadii.pill),
              border: Border.all(
                  color: AppColors.premium.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.star_rounded,
                    color: AppColors.premium, size: 13),
                SizedBox(width: 4),
                Text('Premium',
                    style: TextStyle(
                        color: AppColors.premium,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),

        // Actions row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Privacy toggle
            _buildActionButton(
              icon: u.isProfilePublic
                  ? Icons.public_rounded
                  : Icons.lock_rounded,
              label: u.isProfilePublic ? 'Public' : 'Private',
              onTap: _updatingVisibility ? null : _toggleProfileVisibility,
              loading: _updatingVisibility,
            ),
            const SizedBox(width: 10),
            // Stats toggle (premium only)
            if (u.isPremium) ...[
              _buildActionButton(
                icon: Icons.bar_chart_rounded,
                label: 'Stats',
                onTap: () => setState(
                    () => _showPremiumStats = !_showPremiumStats),
                active: _showPremiumStats,
              ),
              const SizedBox(width: 10),
              // Export (premium only)
              _buildActionButton(
                icon: Icons.download_outlined,
                label: 'Export',
                onTap: _exportData,
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    bool loading = false,
    bool active = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.primarySoft : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppRadii.sm),
          border: Border.all(
            color: active ? AppColors.primary : AppColors.border,
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.primary),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon,
                      color: active ? AppColors.primary : AppColors.textMuted,
                      size: 15),
                  const SizedBox(width: 5),
                  Text(
                    label,
                    style: TextStyle(
                      color: active
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _exportData() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16, height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColors.primary),
            ),
            SizedBox(width: 12),
            Text('Preparing export...'),
          ],
        ),
        duration: Duration(seconds: 30),
        backgroundColor: AppColors.surface,
      ),
    );

    try {
      final response = await ApiClient.get('export/me');

      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      final dir = await getApplicationDocumentsDirectory();
      final fileName =
          'progressio_export_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(response.bodyBytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export saved: $fileName'),
            backgroundColor: AppColors.success,
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // ── STATS SECTION ────────────────────────────────────────────────────────────

  Widget _buildStatsSection() {
    if (_loadingStats) {
      return _buildSectionSkeleton('Statistics');
    }

    if (_basicStats == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(title: 'Statistics'),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                  child: _KpiCard(
                      value: '${_basicStats!.totalCompleted}',
                      label: 'Completed',
                      color: AppColors.success)),
              const SizedBox(width: 10),
              Expanded(
                  child: _KpiCard(
                      value: '${_basicStats!.totalInProgress}',
                      label: 'In Progress',
                      color: AppColors.primary)),
              const SizedBox(width: 10),
              Expanded(
                  child: _KpiCard(
                      value: '${_basicStats!.totalCancelled}',
                      label: 'Cancelled',
                      color: AppColors.error)),
            ],
          ),

          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                  child: _KpiCard(
                      value: '${_basicStats!.currentStreak}',
                      label: 'Current Streak',
                      color: AppColors.warning,
                      icon: Icons.local_fire_department_rounded)),
              const SizedBox(width: 10),
              Expanded(
                  child: _KpiCard(
                      value: '${_basicStats!.longestStreak}',
                      label: 'Longest Streak',
                      color: AppColors.secondary)),
            ],
          ),

          if (AuthProvider.isPremium && _premiumStats != null &&
              _showPremiumStats) ...[
            const SizedBox(height: 20),
            _buildPremiumStats(),
          ] else if (AuthProvider.isPremium && !_showPremiumStats) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () =>
                  setState(() => _showPremiumStats = true),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: AppDecorations.panel(
                    borderColor: AppColors.premium),
                child: const Row(
                  children: [
                    Icon(Icons.bar_chart_rounded,
                        color: AppColors.premium),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Tap to view premium statistics',
                        style: TextStyle(
                            color: AppColors.premium,
                            fontSize: 13,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    Icon(Icons.chevron_right,
                        color: AppColors.premium),
                  ],
                ),
              ),
            ),
          ] else if (!AuthProvider.isPremium) ...[
            const SizedBox(height: 12),
            _buildPremiumLockedCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildPremiumStats() {
    final ps = _premiumStats!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: 'Hours Tracked', small: true),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
                child: _KpiCard(
                    value: ps.totalWatchHours.toStringAsFixed(1),
                    label: 'Watch h',
                    color: AppColors.info)),
            const SizedBox(width: 10),
            Expanded(
                child: _KpiCard(
                    value: ps.totalReadHours.toStringAsFixed(1),
                    label: 'Read h',
                    color: AppColors.success)),
            const SizedBox(width: 10),
            Expanded(
                child: _KpiCard(
                    value: ps.totalGameHours.toStringAsFixed(1),
                    label: 'Game h',
                    color: AppColors.warning)),
          ],
        ),
        if (ps.topGenres.isNotEmpty) ...[
          const SizedBox(height: 16),
          const _SectionTitle(title: 'Top Genres', small: true),
          const SizedBox(height: 10),
          ...ps.topGenres
              .take(5)
              .map((g) => _GenreStatRow(genre: g))
              .toList(),
        ],
      ],
    );
  }

  Widget _buildPremiumLockedCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.panel(),
      child: Column(
        children: [
          const Icon(Icons.lock_rounded,
              color: AppColors.textFaint, size: 32),
          const SizedBox(height: 10),
          const Text(
            'Advanced Statistics',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Upgrade to Premium to unlock hours tracked, genre breakdown, streak heatmap and Wrapped.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: AppColors.textMuted, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final result = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => const PremiumScreen(),
                  ),
                );
                if (result == true && mounted) {
                  _loadAll();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.premium,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppRadii.md)),
              ),
              child: const Text(
                'Upgrade to Premium',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── ACHIEVEMENTS SECTION ─────────────────────────────────────────────────────

  Widget _buildAchievementsSection() {
    if (_loadingAchievements) {
      return _buildSectionSkeleton('Achievements');
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(title: 'Achievements'),
          const SizedBox(height: 14),
          if (_achievements.isEmpty)
            const Text(
              'No achievements yet. Keep tracking to earn them!',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            )
          else
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _achievements.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (ctx, i) {
                  final a = _achievements[i];
                  return _AchievementChip(
                    name: a['achievementName'] ?? '',
                    iconUrl: a['achievementIconUrl'],
                    earnedAt: a['earnedAt'] != null
                        ? DateTime.parse(a['earnedAt'])
                        : null,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  // ── LISTS SECTION ────────────────────────────────────────────────────────────

  Widget _buildListsSection() {
    if (_loadingLists) {
      return _buildSectionSkeleton('My Lists');
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(title: 'My Lists'),
          const SizedBox(height: 14),
          if (_myLists.isEmpty)
            const Text(
              'No lists yet. Create one from the Lists screen.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            )
          else
            ..._myLists.take(5).map((l) => _ListRow(list: l)).toList(),
        ],
      ),
    );
  }

  // ── QUICK LINKS ──────────────────────────────────────────────────────────────

  Widget _buildQuickLinks() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(title: 'More'),
          const SizedBox(height: 10),
          _quickLinkTile(
            icon: Icons.edit_outlined,
            label: 'Edit Profile',
            onTap: _openEditProfile,
          ),
          _quickLinkTile(
            icon: Icons.bar_chart_rounded,
            label: 'Full Stats',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StatsScreen()),
            ),
          ),
          _quickLinkTile(
            icon: Icons.emoji_events_rounded,
            label: 'All Achievements',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const AchievementsScreen()),
            ),
          ),
          _quickLinkTile(
            icon: Icons.lock_reset_rounded,
            label: 'Change Password',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const ChangePasswordScreen()),
            ),
          ),
        ],
      ),
    );
  }

  // ── LOGOUT SECTION ───────────────────────────────────────────────────────────

  Widget _buildLogoutSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, 0),
      child: InkWell(
        onTap: _logout,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: AppDecorations.panel(borderColor: AppColors.error.withOpacity(0.3)),
          child: Row(
            children: [
              Icon(Icons.logout_rounded, color: AppColors.error, size: 18),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Sign Out',
                  style: TextStyle(
                    color: AppColors.error,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: AppColors.error.withOpacity(0.5), size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quickLinkTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.sm),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: AppDecorations.panel(),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textMuted, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textFaint, size: 18),
          ],
        ),
      ),
    );
  }

  // ── HELPERS ──────────────────────────────────────────────────────────────────

  Widget _buildSectionSkeleton(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox(width: 120, height: 16),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: SkeletonBox(width: double.infinity, height: 72)),
              const SizedBox(width: 10),
              Expanded(child: SkeletonBox(width: double.infinity, height: 72)),
              const SizedBox(width: 10),
              Expanded(child: SkeletonBox(width: double.infinity, height: 72)),
            ],
          )
        ],
      ),
    );
  }

  Widget _defaultAvatar({double size = 36}) {
    return Container(
      width: size,
      height: size,
      color: AppColors.surface,
      child: Icon(Icons.person,
          color: AppColors.textFaint, size: size * 0.5),
    );
  }
}

// ── SHARED SMALL WIDGETS ─────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  final bool small;

  const _SectionTitle({required this.title, this.small = false});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        color: AppColors.textPrimary,
        fontSize: small ? 14 : 16,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final IconData? icon;

  const _KpiCard({
    required this.value,
    required this.label,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: AppDecorations.panel(),
      child: Column(
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
          ],
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: AppColors.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _GenreStatRow extends StatelessWidget {
  final GenreStats genre;

  const _GenreStatRow({required this.genre});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              genre.genreName,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
          Expanded(
            flex: 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: genre.completionRate.clamp(0.0, 1.0),
                backgroundColor: AppColors.surfaceElevated,
                valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.primary),
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 40,
            child: Text(
              '${(genre.completionRate * 100).round()}%',
              textAlign: TextAlign.right,
              style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementChip extends StatelessWidget {
  final String name;
  final String? iconUrl;
  final DateTime? earnedAt;

  const _AchievementChip(
      {required this.name, this.iconUrl, this.earnedAt});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 86,
      padding: const EdgeInsets.all(10),
      decoration: AppDecorations.panel(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          iconUrl != null && iconUrl!.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: iconUrl!,
                  width: 32,
                  height: 32,
                  fit: BoxFit.contain,
                  placeholder: (_, __) => const Icon(
                      Icons.emoji_events_rounded,
                      color: AppColors.premium,
                      size: 32),
                  errorWidget: (_, __, ___) => const Icon(
                      Icons.emoji_events_rounded,
                      color: AppColors.premium,
                      size: 32),
                )
              : const Icon(Icons.emoji_events_rounded,
                  color: AppColors.premium, size: 32),
          const SizedBox(height: 6),
          Text(
            name,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                height: 1.3),
          ),
        ],
      ),
    );
  }
}

class _ListRow extends StatelessWidget {
  final UserList list;

  const _ListRow({required this.list});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: AppDecorations.panel(),
      child: Row(
        children: [
          Icon(
            list.isShared
                ? Icons.group_rounded
                : list.isPublic
                    ? Icons.public_rounded
                    : Icons.lock_rounded,
            color: AppColors.textMuted,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              list.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            '${list.itemCount} items',
            style: const TextStyle(
                color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
