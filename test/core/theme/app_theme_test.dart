import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_tracker/core/theme/app_colors.dart';
import 'package:my_budget_tracker/core/theme/app_spacing.dart';
import 'package:my_budget_tracker/core/theme/app_radius.dart';
import 'package:my_budget_tracker/core/theme/app_theme.dart';

void main() {
  group('AppTheme & Tokens Tests', () {
    test('AppColors defines semantic and brand colors', () {
      expect(AppColors.primary, isNotNull);
      expect(AppColors.brandBlue, const Color(0xFF2563EB));
      expect(AppColors.brandPurple, const Color(0xFF7C3AED));
      expect(AppColors.brandGradient.colors, [
        const Color(0xFF2563EB),
        const Color(0xFF7C3AED),
      ]);
      expect(AppColors.income, const Color(0xFF10B981));
      expect(AppColors.expense, const Color(0xFFEF4444));
      expect(AppColors.transfer, const Color(0xFF3B82F6));
      expect(AppColors.savings, const Color(0xFFF59E0B));
    });

    test('AppSpacing defines consistent 4px-based grid constants', () {
      expect(AppSpacing.xs, 4.0);
      expect(AppSpacing.sm, 8.0);
      expect(AppSpacing.md, 12.0);
      expect(AppSpacing.lg, 16.0);
      expect(AppSpacing.xl, 20.0);
      expect(AppSpacing.xxl, 24.0);
      expect(AppSpacing.hero, 32.0);
    });

    test('AppRadius defines consistent corner radius constants', () {
      expect(AppRadius.sm, 8.0);
      expect(AppRadius.md, 12.0);
      expect(AppRadius.card, 16.0);
      expect(AppRadius.sheet, 24.0);
      expect(AppRadius.pill, 999.0);
    });

    test('AppTheme creates light and dark themes with FinancialColors extension', () {
      final light = AppTheme.lightTheme;
      final dark = AppTheme.darkTheme;

      expect(light.useMaterial3, isTrue);
      expect(dark.useMaterial3, isTrue);
      expect(light.brightness, Brightness.light);
      expect(dark.brightness, Brightness.dark);

      final lightFinColors = light.extension<FinancialColors>();
      expect(lightFinColors, isNotNull);
      expect(lightFinColors!.income, AppColors.income);
      expect(lightFinColors.expense, AppColors.expense);
      expect(lightFinColors.transfer, AppColors.transfer);
      expect(lightFinColors.savings, AppColors.savings);

      final darkFinColors = dark.extension<FinancialColors>();
      expect(darkFinColors, isNotNull);
      expect(darkFinColors!.income, AppColors.income);
      expect(darkFinColors.expense, AppColors.expense);

      // Verify FinancialColors copyWith and lerp
      final copied = lightFinColors.copyWith(income: Colors.green);
      expect(copied.income, Colors.green);
      expect(copied.expense, AppColors.expense);

      final lerped = lightFinColors.lerp(copied, 0.5);
      expect(lerped.income, Color.lerp(AppColors.income, Colors.green, 0.5));
    });
  });
}
