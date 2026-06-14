import 'package:flutter/material.dart';
import 'package:progressio_desktop/utils/app_colors.dart';

class AppSpacing {
  static const double xs = 6;
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 18;
  static const double xl = 24;
  static const double xxl = 32;
}

class AppRadii {
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 18;
  static const double xl = 24;
  static const double pill = 999;
}

class AppShadows {
  static List<BoxShadow> get soft => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.28),
          blurRadius: 32,
          offset: const Offset(0, 18),
        ),
      ];

  static List<BoxShadow> get orangeGlow => [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.22),
          blurRadius: 36,
          offset: const Offset(0, 18),
        ),
      ];
}

class AppDecorations {
  static BoxDecoration panel({
    Color color = AppColors.card,
    double radius = AppRadii.lg,
    Color borderColor = AppColors.border,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor),
      boxShadow: AppShadows.soft,
    );
  }

  static BoxDecoration brandedMark({double radius = AppRadii.md}) {
    return BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.primaryHover, AppColors.primary],
      ),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: Colors.white24),
      boxShadow: AppShadows.orangeGlow,
    );
  }
}

class AppBrandMark extends StatelessWidget {
  const AppBrandMark({super.key, this.size = 44, this.iconSize = 25});

  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: AppDecorations.brandedMark(radius: size * 0.28),
      child: Icon(
        Icons.play_circle_filled_rounded,
        color: Colors.black,
        size: iconSize,
      ),
    );
  }
}

class AppShellBackground extends StatelessWidget {
  const AppShellBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.background,
        gradient: RadialGradient(
          center: Alignment.topRight,
          radius: 1.25,
          colors: [
            AppColors.primarySubtle,
            Color(0x00111111),
            AppColors.background,
          ],
          stops: [0, 0.42, 1],
        ),
      ),
      child: child,
    );
  }
}
