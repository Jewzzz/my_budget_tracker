import 'package:flutter/material.dart';

abstract class AppBranding {
  static const String appName = 'MyBudget';
  static const String appSubtitle = 'Personal Budget Tracker';
  static const String appIconAsset = 'assets/branding/app_icon.png';

  // Splash Screen Background Color
  static const Color splashBackgroundColor = Colors.white;

  // Blue and purple gradient branding (modern fintech)
  static const Color brandBlue = Color(0xFF2563EB); // Royal Blue
  static const Color brandPurple = Color(0xFF7C3AED); // Violet / Purple

  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brandBlue, brandPurple],
  );
}
