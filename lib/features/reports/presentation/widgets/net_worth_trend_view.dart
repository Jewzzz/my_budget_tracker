import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
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
    final changePrefix = isChangePositive ? '+' : '';

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        // Summary Metrics Cards (2x1)
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                context,
                title: 'Current Net Worth',
                amount: report.currentNetWorth.format(),
                color: theme.colorScheme.primary,
                icon: Icons.account_balance,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                context,
                title: 'Net Change',
                amount: '$changePrefix${report.netChange.format()}',
                color: isChangePositive ? AppColors.income : AppColors.expense,
                icon: isChangePositive ? Icons.trending_up : Icons.trending_down,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Line Chart Card
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.colorScheme.outlineVariant.withAlpha(120)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Net Worth Trajectory',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
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
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required String amount,
    required Color color,
    required IconData icon,
  }) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withAlpha(120)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: color.withAlpha(35),
                  child: Icon(icon, size: 14, color: color),
                ),
                const SizedBox(width: 6),
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
            const SizedBox(height: 8),
            Text(
              amount,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
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
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              final idx = spot.x.toInt();
              if (idx >= 0 && idx < points.length) {
                final pt = points[idx];
                return LineTooltipItem(
                  '${pt.label}\n${pt.netWorth.format()}',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
            reservedSize: 46,
            getTitlesWidget: (val, meta) {
              if (val < 0) return const SizedBox.shrink();
              return Text(
                '\$${val >= 1000 ? "${(val / 1000).toStringAsFixed(0)}k" : val.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 10),
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
                // Show title on every 1st, middle, and last point if many
                if (points.length > 6 && idx % 2 != 0 && idx != points.length - 1) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    points[idx].label,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
      gridData: const FlGridData(show: true, drawVerticalLine: false),
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
                primaryColor.withAlpha(70),
                primaryColor.withAlpha(5),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
