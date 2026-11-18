import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/reports_timeframe.dart';

class ReportsTimeframeSelector extends StatelessWidget {
  final ReportsTimeframe selectedTimeframe;
  final DateTimeRange? customRange;
  final void Function(ReportsTimeframe timeframe, DateTimeRange? customRange) onSelected;

  const ReportsTimeframeSelector({
    super.key,
    required this.selectedTimeframe,
    this.customRange,
    required this.onSelected,
  });

  Future<void> _pickCustomRange(BuildContext context) async {
    final now = DateTime.now();
    final initialRange = customRange ??
        DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month + 1, 0),
        );

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDateRange: initialRange,
    );

    if (picked != null) {
      onSelected(ReportsTimeframe.custom, picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: ReportsTimeframe.values.map((timeframe) {
          final isSelected = timeframe == selectedTimeframe;
          String label = timeframe.label;

          if (timeframe == ReportsTimeframe.custom && customRange != null) {
            final f = DateFormat.MMMd();
            label = '${f.format(customRange!.start)} - ${f.format(customRange!.end)}';
          }

          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: ChoiceChip(
              label: Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              selected: isSelected,
              showCheckmark: false,
              selectedColor: theme.colorScheme.primaryContainer,
              backgroundColor: theme.colorScheme.surfaceContainerHighest.withAlpha(90),
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.pillBorder,
                side: BorderSide(
                  color: isSelected
                      ? theme.colorScheme.primary.withAlpha(160)
                      : theme.colorScheme.outlineVariant.withAlpha(80),
                ),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: AppSpacing.xs,
              ),
              onSelected: (selected) {
                if (!selected) return;
                if (timeframe == ReportsTimeframe.custom) {
                  _pickCustomRange(context);
                } else {
                  onSelected(timeframe, null);
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}
