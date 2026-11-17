import 'package:flutter/material.dart';
import 'app_colors.dart';

@immutable
class FinancialColors extends ThemeExtension<FinancialColors> {
  final Color income;
  final Color expense;
  final Color transfer;
  final Color savings;

  const FinancialColors({
    required this.income,
    required this.expense,
    required this.transfer,
    required this.savings,
  });

  @override
  FinancialColors copyWith({
    Color? income,
    Color? expense,
    Color? transfer,
    Color? savings,
  }) {
    return FinancialColors(
      income: income ?? this.income,
      expense: expense ?? this.expense,
      transfer: transfer ?? this.transfer,
      savings: savings ?? this.savings,
    );
  }

  @override
  FinancialColors lerp(ThemeExtension<FinancialColors>? other, double t) {
    if (other is! FinancialColors) return this;
    return FinancialColors(
      income: Color.lerp(income, other.income, t) ?? income,
      expense: Color.lerp(expense, other.expense, t) ?? expense,
      transfer: Color.lerp(transfer, other.transfer, t) ?? transfer,
      savings: Color.lerp(savings, other.savings, t) ?? savings,
    );
  }
}

abstract class AppTheme {
  static ThemeData _buildTheme(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      extensions: const [
        FinancialColors(
          income: AppColors.income,
          expense: AppColors.expense,
          transfer: AppColors.transfer,
          savings: AppColors.savings,
        ),
      ],
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 3,
        indicatorColor: colorScheme.primaryContainer,
      ),
    );
  }

  static ThemeData get lightTheme => _buildTheme(Brightness.light);
  static ThemeData get darkTheme => _buildTheme(Brightness.dark);
}
