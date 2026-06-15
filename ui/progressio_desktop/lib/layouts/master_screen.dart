import 'package:flutter/material.dart';
import 'package:progressio_desktop/core/api_client.dart';
import 'package:progressio_desktop/providers/auth_provider.dart';
import 'package:progressio_desktop/screens/achievement_list_screen.dart';
import 'package:progressio_desktop/screens/age_rating_screen.dart';
import 'package:progressio_desktop/screens/chapter_list_screen.dart';
import 'package:progressio_desktop/screens/character_list_screen.dart';
import 'package:progressio_desktop/screens/content_list_screen.dart';
import 'package:progressio_desktop/screens/content_type_screen.dart';
import 'package:progressio_desktop/screens/country_screen.dart';
import 'package:progressio_desktop/screens/episode_comment_list_screen.dart';
import 'package:progressio_desktop/screens/genre_screen.dart';
import 'package:progressio_desktop/screens/language_screen.dart';
import 'package:progressio_desktop/screens/login_screen.dart';
import 'package:progressio_desktop/screens/platform_screen.dart';
import 'package:progressio_desktop/screens/report_screen.dart';
import 'package:progressio_desktop/screens/season_list_screen.dart';
import 'package:progressio_desktop/screens/stats_dashboard_screen.dart';
import 'package:progressio_desktop/screens/subscription_list_screen.dart';
import 'package:progressio_desktop/screens/user_list_screen.dart';
import 'package:progressio_desktop/utils/app_colors.dart';
import 'package:progressio_desktop/widgets/app_ui.dart';

class MasterScreen extends StatelessWidget {
  const MasterScreen({super.key, required this.child, required this.title});

  final Widget child;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundRaised,
        foregroundColor: AppColors.textPrimary,
        toolbarHeight: 66,
        titleSpacing: 6,
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 18),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.35),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.admin_panel_settings_outlined,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Admin',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.hairline),
        ),
      ),
      drawer: Drawer(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 46, 18, 20),
              decoration: const BoxDecoration(
                color: AppColors.surfaceSoft,
                border: Border(
                  bottom: BorderSide(color: AppColors.hairline),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const AppBrandMark(size: 46, iconSize: 27),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Progressio',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Admin Panel',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                children: [
                  _navSection('Content'),
                  _navItem(
                    context: context,
                    icon: Icons.movie_creation_outlined,
                    label: 'Content',
                    screen: const ContentListScreen(),
                  ),
                  _navItem(
                    context: context,
                    icon: Icons.video_library_outlined,
                    label: 'Seasons & Episodes',
                    screen: const SeasonListScreen(),
                  ),
                  _navItem(
                    context: context,
                    icon: Icons.menu_book_outlined,
                    label: 'Chapters',
                    screen: const ChapterListScreen(),
                  ),
                  _navItem(
                    context: context,
                    icon: Icons.groups_2_outlined,
                    label: 'Characters',
                    screen: const CharacterListScreen(),
                  ),
                  _navItem(
                    context: context,
                    icon: Icons.mode_comment_outlined,
                    label: 'Comments',
                    screen: const EpisodeCommentListScreen(),
                  ),
                  _navSection('Users'),
                  _navItem(
                    context: context,
                    icon: Icons.person_outline,
                    label: 'Users',
                    screen: const UserListScreen(),
                  ),
                  _navItem(
                    context: context,
                    icon: Icons.credit_card_outlined,
                    label: 'Subscriptions',
                    screen: const SubscriptionListScreen(),
                  ),
                  _navItem(
                    context: context,
                    icon: Icons.emoji_events_outlined,
                    label: 'Achievements',
                    screen: const AchievementListScreen(),
                  ),
                  _navSection('Reference'),
                  _navItem(
                    context: context,
                    icon: Icons.category_outlined,
                    label: 'Genres',
                    screen: const GenreScreen(),
                  ),
                  _navItem(
                    context: context,
                    icon: Icons.list_alt_outlined,
                    label: 'Content Types',
                    screen: const ContentTypeScreen(),
                  ),
                  _navItem(
                    context: context,
                    icon: Icons.family_restroom_outlined,
                    label: 'Age Ratings',
                    screen: const AgeRatingScreen(),
                  ),
                  _navItem(
                    context: context,
                    icon: Icons.translate_outlined,
                    label: 'Languages',
                    screen: const LanguageScreen(),
                  ),
                  _navItem(
                    context: context,
                    icon: Icons.flag_outlined,
                    label: 'Countries & Cities',
                    screen: const CountryScreen(),
                  ),
                  _navItem(
                    context: context,
                    icon: Icons.devices_other_outlined,
                    label: 'Platforms',
                    screen: const PlatformScreen(),
                  ),
                  _navSection('Analytics'),
                  _navItem(
                    context: context,
                    icon: Icons.dashboard_outlined,
                    label: 'Stats Dashboard',
                    screen: const StatsDashboardScreen(),
                  ),
                  _navItem(
                    context: context,
                    icon: Icons.picture_as_pdf_outlined,
                    label: 'Reports',
                    screen: const ReportScreen(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.hairline),
            Padding(
              padding: const EdgeInsets.all(10),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                leading: const Icon(
                  Icons.logout_rounded,
                  color: AppColors.error,
                ),
                title: const Text(
                  'Sign Out',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onTap: () => _logout(context),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: AppShellBackground(
          child: SizedBox.expand(child: child),
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final refreshToken = AuthProvider.refreshToken;
    try {
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await ApiClient.post(
          'auth/logout',
          body: {'refreshToken': refreshToken},
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sign out failed: $e'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    AuthProvider.clear();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Widget _navSection(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 18, 12, 8),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _navItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Widget screen,
  }) {
    final selected = title == label ||
        (title == 'Seasons' && label == 'Seasons & Episodes') ||
        (title.startsWith('Episodes') && label == 'Seasons & Episodes') ||
        (title == 'Comment Moderation' && label == 'Comments') ||
        (title == 'Countries & Cities' && label == 'Countries & Cities') ||
        (title == 'Stats Dashboard' && label == 'Stats Dashboard');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySoft : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
            color: selected ? AppColors.primaryGlow : Colors.transparent,
          ),
        ),
        child: ListTile(
          dense: true,
          minLeadingWidth: 24,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          leading: Icon(
            icon,
            color: selected ? AppColors.primary : AppColors.textMuted,
            size: 21,
          ),
          title: Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.textPrimary : AppColors.textSecondary,
              fontSize: 14,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
          hoverColor: AppColors.primarySoft,
          splashColor: AppColors.primarySoft,
          onTap: () {
            Navigator.pop(context);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => screen),
            );
          },
        ),
      ),
    );
  }
}