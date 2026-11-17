import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../value_objects/money.dart';

class MoneyText extends StatelessWidget {
  final Money amount;
  final TextStyle? style;
  final bool showSign;
  final bool autoColor;
  final Color? color;
  final String? prefix;

  const MoneyText({
    super.key,
    required this.amount,
    this.style,
    this.showSign = false,
    this.autoColor = false,
    this.color,
    this.prefix,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isNegative = amount.isNegative;
    final isPositive = amount.isPositive;

    String formatted = amount.abs().format();
    if (isNegative) {
      formatted = '-$formatted';
    } else if (showSign && isPositive) {
      formatted = '+$formatted';
    }
    if (prefix != null) {
      formatted = '$prefix$formatted';
    }

    Color? effectiveColor = color;
    if (effectiveColor == null && autoColor) {
      if (isNegative) {
        effectiveColor = AppColors.expense;
      } else if (isPositive) {
        effectiveColor = AppColors.income;
      } else {
        effectiveColor = theme.colorScheme.onSurface;
      }
    }

    final baseStyle = style ?? theme.textTheme.bodyMedium;
    final effectiveStyle = baseStyle?.copyWith(
      color: effectiveColor ?? baseStyle.color,
      fontFeatures: [
        ...?baseStyle.fontFeatures,
        const FontFeature.tabularFigures(),
      ],
    );

    return Text(
      formatted,
      style: effectiveStyle,
    );
  }
}
