import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_tracker/core/presentation/components/app_bottom_sheet.dart';
import 'package:my_budget_tracker/core/theme/app_theme.dart';

void main() {
  group('AppBottomSheet Component Tests', () {
    testWidgets('renders title, drag handle, and child content', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => const AppBottomSheet(
                      title: 'Add Account',
                      child: Text('Sheet Body'),
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Add Account'), findsOneWidget);
      expect(find.text('Sheet Body'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('Sheet Body'), findsNothing);
    });
  });
}
