import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:progressio_mobile/core/api_client.dart';
import 'package:progressio_mobile/core/api_config.dart';
import 'package:progressio_mobile/screens/home_screen.dart';
import 'package:provider/provider.dart';

import 'package:progressio_mobile/providers/achievement_provider.dart';

import 'package:progressio_mobile/providers/calendar_provider.dart';
import 'package:progressio_mobile/providers/chapter_provider.dart';
import 'package:progressio_mobile/providers/character_provider.dart';
import 'package:progressio_mobile/providers/comment_provider.dart';
import 'package:progressio_mobile/providers/content_provider.dart';
import 'package:progressio_mobile/providers/content_type_provider.dart';
import 'package:progressio_mobile/providers/episode_provider.dart';
import 'package:progressio_mobile/providers/feed_provider.dart';
import 'package:progressio_mobile/providers/genre_provider.dart';
import 'package:progressio_mobile/providers/notification_provider.dart';
import 'package:progressio_mobile/providers/payment_provider.dart';
import 'package:progressio_mobile/providers/progress_provider.dart';
import 'package:progressio_mobile/providers/recommendation_provider.dart';
import 'package:progressio_mobile/providers/review_provider.dart';
import 'package:progressio_mobile/providers/season_provider.dart';
import 'package:progressio_mobile/providers/stats_provider.dart';
import 'package:progressio_mobile/providers/subscription_provider.dart';
import 'package:progressio_mobile/providers/user_list_provider.dart';
import 'package:progressio_mobile/providers/user_provider.dart';
import 'package:progressio_mobile/screens/login_screen.dart';
import 'package:progressio_mobile/utils/app_colors.dart';
import 'package:progressio_mobile/providers/vote_provider.dart';
import 'package:progressio_mobile/providers/auth_provider.dart';


import 'package:flutter_stripe/flutter_stripe.dart';
final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

 
  await AuthProvider.tryRestoreSession();

  debugPrint('MAIN START');

  try {
    debugPrint('STRIPE BEFORE');

    if (ApiConfig.stripePublishableKey.isEmpty) {
      throw Exception('STRIPE_PUBLISHABLE_KEY is not configured.');
    }

    Stripe.publishableKey = ApiConfig.stripePublishableKey;
    await Stripe.instance.applySettings();

    debugPrint('STRIPE AFTER');
  } catch (e) {
    debugPrint('STRIPE INIT ERROR: $e');
  }

  debugPrint('RUNAPP BEFORE');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ContentProvider()),
        ChangeNotifierProvider(create: (_) => ContentTypeProvider()),
        ChangeNotifierProvider(create: (_) => GenreProvider()),
        ChangeNotifierProvider(create: (_) => SeasonProvider()),
        ChangeNotifierProvider(create: (_) => EpisodeProvider()),
        ChangeNotifierProvider(create: (_) => ChapterProvider()),
        ChangeNotifierProvider(create: (_) => CharacterProvider()),
        ChangeNotifierProvider(create: (_) => CommentProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
        ChangeNotifierProvider(create: (_) => AchievementProvider()),
        ChangeNotifierProvider(create: (_) => ProgressProvider()),
        ChangeNotifierProvider(create: (_) => RecommendationProvider()),
        ChangeNotifierProvider(create: (_) => CalendarProvider()),
        ChangeNotifierProvider(create: (_) => ReviewProvider()),
        ChangeNotifierProvider(create: (_) => FeedProvider()),
        ChangeNotifierProvider(create: (_) => StatsProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => UserListProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
        ChangeNotifierProvider(create: (_) => VoteProvider()),
      ],
      child: const ProgressioApp(),
    ),
  );

  debugPrint('RUNAPP AFTER');
}

class ProgressioApp extends StatelessWidget {
  const ProgressioApp({super.key});

  @override
  Widget build(BuildContext context) {
    ApiClient.onSessionExpired = () {
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    };

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Progressio',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
     
      home: AuthProvider.isLoggedIn
          ? const HomeScreen()
          : const LoginScreen(),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: Colors.black,
        onSurface: AppColors.textPrimary,
      ),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.input,
        hintStyle: const TextStyle(color: AppColors.textFaint),
        labelStyle: const TextStyle(color: AppColors.textMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.divider),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.backgroundRaised,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textFaint,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }
}