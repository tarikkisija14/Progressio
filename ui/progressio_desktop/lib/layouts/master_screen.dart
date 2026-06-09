import 'package:flutter/material.dart';
import 'package:progressio_desktop/screens/content_list_screen.dart';
import 'package:progressio_desktop/screens/season_list_screen.dart';
import 'package:progressio_desktop/utils/app_colors.dart';
import 'package:progressio_desktop/screens/chapter_list_screen.dart';
import 'package:progressio_desktop/screens/character_list_screen.dart';
import 'package:progressio_desktop/screens/episode_comment_list_screen.dart';
import 'package:progressio_desktop/screens/user_list_screen.dart';
import 'package:progressio_desktop/screens/subscription_list_screen.dart';
import 'package:progressio_desktop/screens/achievement_list_screen.dart';
import 'package:progressio_desktop/screens/genre_screen.dart';
import 'package:progressio_desktop/screens/content_type_screen.dart';
import 'package:progressio_desktop/screens/country_screen.dart';
import 'package:progressio_desktop/screens/platform_screen.dart';



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
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.divider),
        ),
      ),
      drawer: Drawer(
        backgroundColor: AppColors.surface,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
              color: AppColors.card,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.play_circle_filled,
                            color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Progressio',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Admin Panel',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _navSection('Content'),
                  _navItem(
                    context: context,
                    icon: Icons.movie,
                    label: 'Content',
                    screen: const ContentListScreen(),
                  ),
                  _navItem(
                    context: context,
                    icon: Icons.view_list,
                    label: 'Seasons & Episodes',
                    screen: const SeasonListScreen(),
                  ),
                  _navItem(
                    context: context,
                    icon: Icons.menu_book,
                    label: 'Chapters',
                    screen: const ChapterListScreen(),
                  ),
                  _navItem(
                  context: context,
                  icon: Icons.people,
                  label: 'Characters',
                  screen: const CharacterListScreen(),
                 ),
                 _navItem(
                   context: context,
                   icon: Icons.comment,
                   label: 'Comments',
                   screen: const EpisodeCommentListScreen(),
                  ),
                  _navSection('Users'),
                  _navItem(
                   context: context,
                   icon: Icons.person,
                   label: 'Users',
                   screen: const UserListScreen(),
                  ),
                  _navItem(
                  context: context,
                  icon: Icons.credit_card,
                  label: 'Subscriptions',
                  screen: const SubscriptionListScreen(),
                ),
                _navItem(
                  context: context,
                  icon: Icons.emoji_events,
                  label: 'Achievements',
                  screen: const AchievementListScreen(),
                 ),
                 _navSection('Reference'),
                 _navItem(
                 context: context,
                 icon: Icons.category,
                 label: 'Genres',
                 screen: const GenreScreen(),
                ),
               _navItem(
                context: context,
                icon: Icons.list_alt,
                label: 'Content Types',
                screen: const ContentTypeScreen(),
                ),
                _navItem(
               context: context,
               icon: Icons.flag,
               label: 'Countries & Cities',
               screen: const CountryScreen(),
               ),
               _navItem(
               context: context,
               icon: Icons.devices_other,
               label: 'Platforms',
               screen: const PlatformScreen(),
              ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: child,
    );
  }

  Widget _navSection(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
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
    return ListTile(
      dense: true,
      leading: Icon(icon, color: AppColors.textSecondary, size: 20),
      title: Text(
        label,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
      ),
      hoverColor: AppColors.card,
      onTap: () {
        Navigator.pop(context);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => screen),
        );
      },
    );
  }
}