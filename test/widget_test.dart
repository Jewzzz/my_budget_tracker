import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_tracker/core/database/app_database.dart';
import 'package:my_budget_tracker/main.dart';
import 'helpers/fake_flutter_secure_storage.dart';

void main() {
  testWidgets('BudgetTrackerApp smoke test renders AppShell', (WidgetTester tester) async {
    final database = AppDatabase.inMemory();
    final secureStorage = createInMemorySecureStorage({
      'pref_primary_currency_backfilled': 'true',
    });

    await tester.pumpWidget(BudgetTrackerApp(
      database: database,
      secureStorage: secureStorage,
    ));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsNWidgets(2));
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.text('Total Balance'), findsOneWidget);

    await database.close();
    await tester.pump(const Duration(milliseconds: 100));
  });
}
