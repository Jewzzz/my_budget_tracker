import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/presentation/components/app_card.dart';
import '../../../../core/presentation/components/money_text.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/value_objects/money.dart';
import '../../domain/entities/cash_flow_report.dart';

class CashFlowView extends StatelessWidget {
  final CashFlowReport report;

  const CashFlowView({
    super.key,
    required this.report,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isNetPositive = !report.netCashFlow.isNegative;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      children: [
        // Summary Metrics Cards (2x2)
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                context,
                title: 'Total Income',
                amount: report.totalIncome,
                color: AppColors.income,
                icon: Icons.arrow_downward,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildMetricCard(
                context,
                title: 'Total Expenses',
                amount: report.totalExpense,
                color: AppColors.expense,
                icon: Icons.arrow_upward,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                context,
                title: 'Net Cash Flow',
                amount: report.netCashFlow,
                color: isNetPositive ? AppColors.income : AppColors.expense,
                icon: isNetPositive ? Icons.trending_up : Icons.trending_down,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildSavingsRateCard(context),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),

        // Comparative Bar Chart Section
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Monthly Cash Flow',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      _buildLegendItem('Income', AppColors.income),
                      const SizedBox(width: AppSpacing.md),
                      _buildLegendItem('Expenses', AppColors.expense),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                height: 220,
                child: report.monthlyData.isEmpty
                    ? Center(
                        child: Text(
                          'No monthly transactions recorded',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : BarChart(
                        _buildBarChartData(context),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required Money amount,
    required Color color,
    required IconData icon,
  }) {
    final theme = Theme.of(context);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 14, color: color),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          MoneyText(
            amount: amount,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavingsRateCard(BuildContext context) {
    final theme = Theme.of(context);
    final rate = report.savingsRate;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: AppColors.income.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.savings_outlined, size: 14, color: AppColors.income),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'Savings Rate',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${rate.toStringAsFixed(1)}%',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.income,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: (rate / 100.0).clamp(0.0, 1.0),
              minHeight: 4,
              color: AppColors.income,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  BarChartData _buildBarChartData(BuildContext context) {
    final theme = Theme.of(context);
    final data = report.monthlyData;
    double maxY = 100.0;
    for (final p in data) {
      final inc = p.income.minorUnits / 100.0;
      final exp = p.expense.minorUnits / 100.0;
      maxY = max(maxY, max(inc, exp));
    }
    maxY *= 1.15; // 15% headroom

    return BarChartData(
      maxY: maxY,
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (_) => theme.colorScheme.surfaceContainerHighest,
          tooltipBorder: BorderSide(
            color: theme.colorScheme.outlineVariant.withAlpha(120),
          ),
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            final month = data[group.x.toInt()].label;
            final isInc = rodIndex == 0;
            final type = isInc ? 'Income' : 'Expense';
            final value = '\$${rod.toY.toStringAsFixed(2)}';
            return BarTooltipItem(
              '$month\n$type: $value',
              TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            );
          },
        ),
      ),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 42,
            getTitlesWidget: (val, meta) {
              if (val == 0) return const SizedBox.shrink();
              return Text(
                '\$${val >= 1000 ? "${(val / 1000).toStringAsFixed(0)}k" : val.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 10,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (val, meta) {
              final index = val.toInt();
              if (index >= 0 && index < data.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    data[index].label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (val) => FlLine(
          color: theme.colorScheme.outlineVariant.withAlpha(40),
          strokeWidth: 1,
        ),
      ),
      borderData: FlBorderData(show: false),
      barGroups: List.generate(data.length, (i) {
        final point = data[i];
        final inc = point.income.minorUnits / 100.0;
        final exp = point.expense.minorUnits / 100.0;

        return BarChartGroupData(
          x: i,
          barsSpace: 4,
          barRods: [
            BarChartRodData(
              toY: inc,
              color: AppColors.income,
              width: 12,
              borderRadius: BorderRadius.circular(4),
            ),
            BarChartRodData(
              toY: exp,
              color: AppColors.expense,
              width: 12,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        );
      }),
    );
  }
}
