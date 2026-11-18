import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/presentation/components/app_card.dart';
import '../../../../core/presentation/components/app_empty_state.dart';
import '../../../../core/presentation/components/category_icon_badge.dart';
import '../../../../core/presentation/components/money_text.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/category_breakdown_report.dart';

class CategoryBreakdownView extends StatefulWidget {
  final CategoryBreakdownReport report;

  const CategoryBreakdownView({
    super.key,
    required this.report,
  });

  @override
  State<CategoryBreakdownView> createState() => _CategoryBreakdownViewState();
}

class _CategoryBreakdownViewState extends State<CategoryBreakdownView> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final report = widget.report;

    if (report.items.isEmpty) {
      return const Center(
        child: AppEmptyState(
          icon: Icons.pie_chart_outline,
          title: 'No Expense Data',
          message: 'No expenses recorded for this timeframe.',
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      children: [
        // Total Expense Overview Banner
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Expenses',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  MoneyText(
                    amount: report.totalExpense,
                    color: AppColors.expense,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Text(
                '${report.items.length} Categories',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Interactive Donut Chart
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: SizedBox(
            height: 220,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          pieTouchResponse == null ||
                          pieTouchResponse.touchedSection == null) {
                        _touchedIndex = -1;
                        return;
                      }
                      _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                borderData: FlBorderData(show: false),
                sectionsSpace: 2,
                centerSpaceRadius: 45,
                sections: List.generate(report.items.length, (i) {
                  final item = report.items[i];
                  final isTouched = i == _touchedIndex;
                  final radius = isTouched ? 55.0 : 45.0;
                  final color = Color(item.category.color);

                  return PieChartSectionData(
                    color: color,
                    value: item.amount.minorUnits / 100.0,
                    title: item.percentage >= 5.0 ? '${item.percentage.toStringAsFixed(0)}%' : '',
                    radius: radius,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Ranked Category List
        Text(
          'Ranked Spending Breakdown',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        ...report.items.map((item) {
          final cat = item.category;
          final color = Color(cat.color);

          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  Row(
                    children: [
                      CategoryIconBadge(
                        iconName: cat.icon,
                        color: color,
                        size: CategoryBadgeSize.medium,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cat.name,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${item.percentage.toStringAsFixed(1)}% of total',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      MoneyText(
                        amount: item.amount,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: (item.percentage / 100.0).clamp(0.0, 1.0),
                      minHeight: 4,
                      color: color,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
