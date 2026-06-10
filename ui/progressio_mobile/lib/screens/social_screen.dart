import 'package:flutter/material.dart';
import 'package:progressio_mobile/utils/app_colors.dart';

class SocialScreen extends StatelessWidget {
  const SocialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(child: Text('Social', style: TextStyle(color: AppColors.textPrimary))),
    );
  }
}