import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract class AppBranding {
  static const String appName = 'MyBudget';
  static const String appSubtitle = 'Personal Budget Tracker';
  static const String appIconAsset = 'assets/branding/app_icon.png';
  static const Color splashBackgroundColor = Colors.white;

  // Delegated to centralized AppColors per ADR 0010
  static const Color brandBlue = AppColors.brandBlue;
  static const Color brandPurple = AppColors.brandPurple;
  static const LinearGradient brandGradient = AppColors.brandGradient;
}
