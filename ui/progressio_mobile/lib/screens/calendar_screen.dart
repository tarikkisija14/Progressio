import 'package:flutter/material.dart';
import 'package:progressio_mobile/utils/app_colors.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(child: Text('Calendar', style: TextStyle(color: AppColors.textPrimary))),
    );
  }
}