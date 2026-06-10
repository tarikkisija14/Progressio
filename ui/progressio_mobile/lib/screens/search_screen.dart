import 'package:flutter/material.dart';
import 'package:progressio_mobile/utils/app_colors.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(child: Text('Search', style: TextStyle(color: AppColors.textPrimary))),
    );
  }
}