import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/category_budget_overview.dart';

class CategoryBudgetCard extends StatelessWidget {
  final CategoryBudgetOverview overview;
  final VoidCallback? onTap;

  const CategoryBudgetCard({
    super.key,
    required this.overview,
    this.onTap,
  });

  IconData _getCategoryIcon(String iconName) {
    switch (iconName) {
      case 'shopping_cart':
        return Icons.shopping_cart_outlined;
      case 'home':
        return Icons.home_outlined;
      case 'restaurant':
        return Icons.restaurant_outlined;
      case 'directions_car':
        return Icons.directions_car_outlined;
      case 'bolt':
        return Icons.bolt_outlined;
      case 'movie':
        return Icons.movie_outlined;
      case 'local_hospital':
        return Icons.local_hospital_outlined;
      case 'work':
        return Icons.work_outlined;
      case 'trending_up':
        return Icons.trending_up_outlined;
      case 'card_giftcard':
        return Icons.card_giftcard_outlined;
      case 'school':
        return Icons.school_outlined;
      case 'menu_book':
        return Icons.menu_book_outlined;
      case 'flight':
        return Icons.flight_outlined;
      case 'pets':
        return Icons.pets_outlined;
      case 'fitness_center':
        return Icons.fitness_center_outlined;
      case 'local_cafe':
        return Icons.local_cafe_outlined;
      default:
        return Icons.category_outlined;
    }
  }

  Color _getProgressColor(double percentage) {
    if (percentage > 1.0) {
      return AppColors.expense;
    } else if (percentage >= 0.8) {
      return Colors.amber.shade700;
    } else {
      return AppColors.income;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final category = overview.category;
    final catColor = Color(category.color);
    final isOverBudget = overview.isOverBudget;
    final percentage = overview.percentageSpent;
    final progressColor = _getProgressColor(percentage);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isOverBudget
              ? theme.colorScheme.error
              : theme.colorScheme.outlineVariant.withAlpha(120),
          width: isOverBudget ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top row: Icon, Category Name, Over-Budget Badge or Percentage
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: catColor.withAlpha(35),
                    child: Icon(_getCategoryIcon(category.icon), color: catColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${overview.spentAmount.format()} of ${overview.budget.limitAmount.format()}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isOverBudget)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            size: 14,
                            color: theme.colorScheme.error,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Over Budget',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Text(
                      '${(percentage * 100).toStringAsFixed(0)}%',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: progressColor,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),

              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: min(1.0, percentage),
                  minHeight: 8,
                  color: progressColor,
                  backgroundColor: progressColor.withAlpha(35),
                ),
              ),
              const SizedBox(height: 8),

              // Bottom status: Remaining or Over by amount
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isOverBudget
                        ? 'Over by ${(overview.spentAmount - overview.budget.limitAmount).format()}'
                        : 'Remaining: ${overview.remainingAmount.format()}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isOverBudget
                          ? theme.colorScheme.error
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant.withAlpha(120),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
