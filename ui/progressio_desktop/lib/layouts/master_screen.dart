import 'package:flutter/material.dart';
import 'package:progressio_desktop/screens/achievement_list_screen.dart';
import 'package:progressio_desktop/screens/chapter_list_screen.dart';
import 'package:progressio_desktop/screens/character_list_screen.dart';
import 'package:progressio_desktop/screens/content_list_screen.dart';
import 'package:progressio_desktop/screens/content_type_screen.dart';
import 'package:progressio_desktop/screens/country_screen.dart';
import 'package:progressio_desktop/screens/episode_comment_list_screen.dart';
import 'package:progressio_desktop/screens/genre_screen.dart';
import 'package:progressio_desktop/screens/platform_screen.dart';
import 'package:progressio_desktop/screens/report_screen.dart';
import 'package:progressio_desktop/screens/season_list_screen.dart';
import 'package:progressio_desktop/screens/stats_dashboard_screen.dart';
import 'package:progressio_desktop/screens/subscription_list_screen.dart';
import 'package:progressio_desktop/screens/user_list_screen.dart';
import 'package:progressio_desktop/utils/app_colors.dart';

class MasterScreen extends StatelessWidget {
  const MasterScreen({super.key, required this.child, required this.title});

  final Widget child;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        title: Text(title),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 18),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.primary.withOpacity(0.35)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.admin_panel_settings_outlined, size: 16, color: AppColors.primary),
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
          child: Container(height: 1, color: AppColors.divider),
        ),
      ),
      drawer: Drawer(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 48, 18, 20),
              decoration: const BoxDecoration(
                color: AppColors.surfaceElevated,
                border: Border(
                  bottom: BorderSide(color: AppColors.divider),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [AppColors.primaryHover, AppColors.primary],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.25),
                              blurRadius: 22,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.play_circle_filled,
                          color: Colors.black,
                          size: 26,
                        ),
                      ),
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
                                letterSpacing: -0.3,
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
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
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
          ],
        ),
      ),
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF111111),
                AppColors.background,
              ],
            ),
          ),
          child: child,
        ),
      ),
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
          letterSpacing: 1.1,
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: ListTile(
        dense: true,
        minLeadingWidth: 24,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: Icon(icon, color: AppColors.textMuted, size: 21),
        title: Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
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
    );
  }
}
