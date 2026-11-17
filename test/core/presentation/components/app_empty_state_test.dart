import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_tracker/core/presentation/components/app_empty_state.dart';
import 'package:my_budget_tracker/core/theme/app_theme.dart';

void main() {
  group('AppEmptyState Component Tests', () {
    testWidgets('renders icon, title, and subtitle correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: AppEmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No Transactions',
              message: 'Add your first transaction using the button below.',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.receipt_long_outlined), findsOneWidget);
      expect(find.text('No Transactions'), findsOneWidget);
      expect(
        find.text('Add your first transaction using the button below.'),
        findsOneWidget,
      );
      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets('renders action button and invokes onAction callback', (tester) async {
      bool actionTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppEmptyState(
              icon: Icons.savings_outlined,
              title: 'No Goals Yet',
              message: 'Create a savings goal to start tracking progress.',
              actionLabel: 'Create Goal',
              onAction: () => actionTriggered = true,
            ),
          ),
        ),
      );

      expect(find.text('Create Goal'), findsOneWidget);
      await tester.tap(find.text('Create Goal'));
      await tester.pumpAndSettle();

      expect(actionTriggered, isTrue);
    });
  });
}
