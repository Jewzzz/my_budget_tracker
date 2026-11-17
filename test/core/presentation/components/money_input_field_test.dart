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
  });
}
