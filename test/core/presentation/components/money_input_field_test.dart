import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_tracker/core/presentation/components/money_input_field.dart';
import 'package:my_budget_tracker/core/theme/app_theme.dart';

void main() {
  group('MoneyInputField Component Tests', () {
    testWidgets('renders currency prefix and allows entering amounts', (tester) async {
      final controller = TextEditingController();
      final formKey = GlobalKey<FormState>();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Form(
              key: formKey,
              child: MoneyInputField(
                controller: controller,
                label: 'Transaction Amount',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Transaction Amount'), findsOneWidget);
      expect(find.text('\$ '), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), '149.99');
      expect(controller.text, '149.99');

      expect(formKey.currentState!.validate(), isTrue);
    });

    testWidgets('validates empty or non-positive amount', (tester) async {
      final controller = TextEditingController();
      final formKey = GlobalKey<FormState>();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Form(
              key: formKey,
              child: MoneyInputField(
                controller: controller,
              ),
            ),
          ),
        ),
      );

      expect(formKey.currentState!.validate(), isFalse);
      await tester.pumpAndSettle();
      expect(find.text('Please enter an amount'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), '0');
      expect(formKey.currentState!.validate(), isFalse);
      await tester.pumpAndSettle();
      expect(find.text('Amount must be greater than 0'), findsOneWidget);
    });

    testWidgets('dynamically formats 0-decimal currency JPY with integer input', (tester) async {
      final controller = TextEditingController();
      final formKey = GlobalKey<FormState>();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Form(
              key: formKey,
              child: MoneyInputField(
                controller: controller,
                currencyCode: 'JPY',
              ),
            ),
          ),
        ),
      );

      expect(find.text('¥ '), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), '15000');
      expect(formKey.currentState!.validate(), isTrue);
      expect(MoneyInputField.parseMinorUnits(controller.text, 'JPY'), 15000);
    });

    testWidgets('dynamically formats 3-decimal currency KWD with 3 decimal places', (tester) async {
      final controller = TextEditingController();
      final formKey = GlobalKey<FormState>();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Form(
              key: formKey,
              child: MoneyInputField(
                controller: controller,
                currencyCode: 'KWD',
              ),
            ),
          ),
        ),
      );

      expect(find.text('KD '), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), '1.250');
      expect(formKey.currentState!.validate(), isTrue);
      // 1.250 KWD * 1000 = 1250 fils
      expect(MoneyInputField.parseMinorUnits(controller.text, 'KWD'), 1250);
    });
  });
}
