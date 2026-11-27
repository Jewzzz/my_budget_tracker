import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/currency/currency_context_extension.dart';
import '../../../../core/presentation/components/app_card.dart';
import '../../../../core/presentation/components/money_text.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/value_objects/money.dart';
import '../../domain/entities/net_worth_trend_report.dart';

class NetWorthTrendView extends StatelessWidget {
  final NetWorthTrendReport report;

  const NetWorthTrendView({
    super.key,
    required this.report,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isChangePositive = !report.netChange.isNegative;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      children: [
        // Summary Metrics Cards (2x1)
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                context,
                title: 'Current Net Worth',
                amount: report.currentNetWorth,
                color: theme.colorScheme.primary,
                icon: Icons.account_balance,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildMetricCard(
                context,
                title: 'Net Change',
                amount: report.netChange,
                showSign: true,
                color: isChangePositive ? AppColors.income : AppColors.expense,
                icon: isChangePositive ? Icons.trending_up : Icons.trending_down,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),

        // Line Chart Card
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Net Worth Trajectory',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                height: 240,
                child: report.points.isEmpty
                    ? Center(
                        child: Text(
                          'No net worth checkpoints available',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : LineChart(
                        _buildLineChartData(context),
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
    bool showSign = false,
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
            showSign: showSign,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  LineChartData _buildLineChartData(BuildContext context) {
    final theme = Theme.of(context);
    final points = report.points;

    double minY = points.isNotEmpty ? points.first.netWorth.minorUnits / 100.0 : 0.0;
    double maxY = minY;

    for (final p in points) {
      final y = p.netWorth.minorUnits / 100.0;
      minY = min(minY, y);
      maxY = max(maxY, y);
    }

    if (minY == maxY) {
      minY = max(0, minY - 100);
      maxY = maxY + 100;
    } else {
      final diff = maxY - minY;
      minY = max(0, minY - (diff * 0.1));
      maxY = maxY + (diff * 0.1);
    }

    final primaryColor = theme.colorScheme.primary;

    return LineChartData(
      minY: minY,
      maxY: maxY,
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => theme.colorScheme.surfaceContainerHighest,
          tooltipBorder: BorderSide(
            color: theme.colorScheme.outlineVariant.withAlpha(120),
          ),
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              final idx = spot.x.toInt();
              if (idx >= 0 && idx < points.length) {
                final pt = points[idx];
                return LineTooltipItem(
                  '${pt.label}\n${context.formatMoney(pt.netWorth)}',
                  TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              }
              return null;
            }).toList();
          },
        ),
      ),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 60,
            getTitlesWidget: (val, meta) {
              if (val < 0) return const SizedBox.shrink();
              return Text(
                context.formatCompactCurrency(val),
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
              final idx = val.toInt();
              if (idx >= 0 && idx < points.length) {
                if (points.length > 6 && idx % 2 != 0 && idx != points.length - 1) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    points[idx].label,
                    style: TextStyle(
                      fontSize: 10,
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
      lineBarsData: [
        LineChartBarData(
          spots: List.generate(points.length, (i) {
            return FlSpot(i.toDouble(), points[i].netWorth.minorUnits / 100.0);
          }),
          isCurved: true,
          color: primaryColor,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(show: points.length <= 10),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                primaryColor.withAlpha(60),
                primaryColor.withAlpha(0),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
