import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_tracker/main.dart';

void main() {
  testWidgets('BudgetTrackerApp smoke test renders AppShell', (WidgetTester tester) async {
    await tester.pumpWidget(const BudgetTrackerApp());

    expect(find.text('Dashboard'), findsNWidgets(2));
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });
}
