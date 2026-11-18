import 'package:flutter/material.dart';

abstract class AppColors {
  // Brand / Slate Palette
  static const Color primary = Color(0xFF0F172A); // Midnight Slate
  static const Color secondary = Color(0xFF1E293B); // Dark Slate
  static const Color tertiary = Color(0xFF334155); // Muted Slate

  // Brand Gradient Tokens (Modern Fintech)
  static const Color brandBlue = Color(0xFF2563EB); // Royal Blue
  static const Color brandPurple = Color(0xFF7C3AED); // Violet / Purple
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brandBlue, brandPurple],
  );

  // Semantic Financial Color Tokens
  static const Color income = Color(0xFF10B981); // Emerald Green
  static const Color expense = Color(0xFFEF4444); // Crimson / Coral Red
  static const Color transfer = Color(0xFF3B82F6); // Royal Blue
  static const Color savings = Color(0xFFF59E0B); // Amber / Gold
}
