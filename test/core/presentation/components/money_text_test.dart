import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_tracker/core/presentation/components/money_text.dart';
import 'package:my_budget_tracker/core/theme/app_colors.dart';
import 'package:my_budget_tracker/core/theme/app_theme.dart';
import 'package:my_budget_tracker/core/value_objects/money.dart';

void main() {
  group('MoneyText Component Tests', () {
    testWidgets('formats Money value object with currency prefix and tabular figures',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: MoneyText(amount: Money(250000)),
          ),
        ),
      );

      expect(find.text('\$ 2,500.00'), findsOneWidget);
    });

    testWidgets('displays explicit positive sign and semantic income color', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: MoneyText(
              amount: Money(15000),
              showSign: true,
              autoColor: true,
            ),
          ),
        ),
      );

      final textWidget = tester.widget<Text>(find.byType(Text));
      expect(textWidget.data, '+\$ 150.00');
      expect(textWidget.style?.color, AppColors.income);
    });

    testWidgets('displays explicit negative sign and semantic expense color', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: MoneyText(
              amount: Money(-8500),
              showSign: true,
              autoColor: true,
            ),
          ),
        ),
      );

      final textWidget = tester.widget<Text>(find.byType(Text));
      expect(textWidget.data, '-\$ 85.00');
      expect(textWidget.style?.color, AppColors.expense);
    });
  });
}
