import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_budget_tracker/core/theme/app_theme.dart';
import 'package:my_budget_tracker/core/value_objects/money.dart';
import 'package:my_budget_tracker/features/accounts/presentation/cubit/accounts_cubit.dart';
import 'package:my_budget_tracker/features/accounts/presentation/cubit/accounts_state.dart';
import 'package:my_budget_tracker/features/app/presentation/app_shell.dart';

class MockAccountsCubit extends MockCubit<AccountsState> implements AccountsCubit {}

void main() {
  group('AppShell Widget Tests', () {
    late AccountsCubit cubit;

    setUp(() {
      cubit = MockAccountsCubit();
      when(() => cubit.state).thenReturn(
        const AccountsLoaded(
          accounts: [],
          totalBalance: Money.zero,
        ),
      );
    });

    Widget buildTestApp({ThemeMode themeMode = ThemeMode.light}) {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        home: BlocProvider<AccountsCubit>.value(
          value: cubit,
          child: const AppShell(),
        ),
      );
    }

    testWidgets('renders all 5 navigation bar destinations and default Dashboard view', (tester) async {
      await tester.pumpWidget(buildTestApp());

      // Verify AppBar title starts as Dashboard
      expect(find.text('Dashboard'), findsNWidgets(2)); // AppBar title + NavigationBar destination
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);

      // Verify all 5 destinations exist in the NavigationBar
      expect(find.text('Transactions'), findsOneWidget);
      expect(find.text('Budgets'), findsOneWidget);
      expect(find.text('Goals'), findsOneWidget);
      expect(find.text('Reports'), findsOneWidget);

      // Verify FAB exists
      expect(find.byType(FloatingActionButton), findsOneWidget);

      // Verify Dashboard content rendered
      expect(find.text('Total Balance'), findsOneWidget);
    });

    testWidgets('switches views and updates AppBar title when navigation items are tapped', (tester) async {
      await tester.pumpWidget(buildTestApp());

      // Tap Transactions
      await tester.tap(find.text('Transactions'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, 'Transactions'), findsOneWidget);
      expect(find.text('Transactions View'), findsOneWidget);

      // Tap Budgets
      await tester.tap(find.text('Budgets'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, 'Budgets'), findsOneWidget);
      expect(find.text('Budgets View'), findsOneWidget);

      // Tap Goals
      await tester.tap(find.text('Goals'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, 'Savings Goals'), findsOneWidget);
      expect(find.text('Goals View'), findsOneWidget);

      // Tap Reports
      await tester.tap(find.text('Reports'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, 'Reports'), findsOneWidget);
      expect(find.text('Reports View'), findsOneWidget);

      // Tap Dashboard
      await tester.tap(find.text('Dashboard'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, 'Dashboard'), findsOneWidget);
      expect(find.text('Total Balance'), findsOneWidget);
    });
  });
}
