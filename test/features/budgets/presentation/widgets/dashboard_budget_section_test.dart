import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_budget_tracker/core/theme/app_theme.dart';
import 'package:my_budget_tracker/core/value_objects/money.dart';
import 'package:my_budget_tracker/features/budgets/domain/entities/budget.dart';
import 'package:my_budget_tracker/features/budgets/domain/entities/category_budget_overview.dart';
import 'package:my_budget_tracker/features/budgets/presentation/cubit/budgets_cubit.dart';
import 'package:my_budget_tracker/features/budgets/presentation/cubit/budgets_state.dart';
import 'package:my_budget_tracker/features/budgets/presentation/widgets/dashboard_budget_section.dart';
import 'package:my_budget_tracker/features/categories/domain/entities/category.dart';

class MockBudgetsCubit extends MockCubit<BudgetsState> implements BudgetsCubit {}

void main() {
  group('DashboardBudgetSection Widget Tests', () {
    late BudgetsCubit budgetsCubit;

    final testCategory = Category(
      id: 'cat-groceries',
      name: 'Groceries',
      type: CategoryType.expense,
      icon: 'shopping_cart',
      color: 0xFF10B981,
    );

    setUp(() {
      budgetsCubit = MockBudgetsCubit();
    });

    Widget buildTestWidget() {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: BlocProvider<BudgetsCubit>.value(
            value: budgetsCubit,
            child: const DashboardBudgetSection(),
          ),
        ),
      );
    }

    testWidgets('renders nothing when no budgets are defined for month', (tester) async {
      when(() => budgetsCubit.state).thenReturn(
        const BudgetsLoaded(year: 2026, month: 5, budgets: []),
      );

      await tester.pumpWidget(buildTestWidget());

      expect(find.text('Monthly Budget'), findsNothing);
    });

    testWidgets('renders budget summary with progress when budgets exist', (tester) async {
      final overview = CategoryBudgetOverview(
        budget: Budget(
          id: 'b-1',
          categoryId: testCategory.id,
          year: 2026,
          month: 5,
          limitAmount: const Money(50000), // $500
        ),
        category: testCategory,
        spentAmount: const Money(20000), // $200
      );

      when(() => budgetsCubit.state).thenReturn(
        BudgetsLoaded(year: 2026, month: 5, budgets: [overview]),
      );

      await tester.pumpWidget(buildTestWidget());

      expect(find.text('Monthly Budget'), findsOneWidget);
      expect(find.text('40% used'), findsOneWidget);
      expect(find.text(r'$200.00 spent of $500.00'), findsOneWidget);
      expect(find.text(r'$300.00 left'), findsOneWidget);
    });

    testWidgets('renders over-budget warning tag when spending exceeds budget', (tester) async {
      final overOverview = CategoryBudgetOverview(
        budget: Budget(
          id: 'b-1',
          categoryId: testCategory.id,
          year: 2026,
          month: 5,
          limitAmount: const Money(10000), // $100
        ),
        category: testCategory,
        spentAmount: const Money(15000), // $150
      );

      when(() => budgetsCubit.state).thenReturn(
        BudgetsLoaded(year: 2026, month: 5, budgets: [overOverview]),
      );

      await tester.pumpWidget(buildTestWidget());

      expect(find.text('Over-Budget (1)'), findsOneWidget);
      expect(find.text(r'Over by $50.00'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });
  });
}
