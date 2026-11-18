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
import 'package:my_budget_tracker/features/budgets/presentation/pages/budgets_page.dart';
import 'package:my_budget_tracker/features/categories/domain/entities/category.dart';
import 'package:my_budget_tracker/features/categories/presentation/cubit/categories_cubit.dart';
import 'package:my_budget_tracker/features/categories/presentation/cubit/categories_state.dart';

class MockBudgetsCubit extends MockCubit<BudgetsState> implements BudgetsCubit {}
class MockCategoriesCubit extends MockCubit<CategoriesState> implements CategoriesCubit {}

void main() {
  group('BudgetsPage Widget Tests', () {
    late BudgetsCubit budgetsCubit;
    late CategoriesCubit categoriesCubit;

    final testCategory = Category(
      id: 'cat-groceries',
      name: 'Groceries',
      type: CategoryType.expense,
      icon: 'shopping_cart',
      color: 0xFF10B981,
    );

    final normalBudget = Budget(
      id: 'b-1',
      categoryId: testCategory.id,
      year: 2026,
      month: 5,
      limitAmount: const Money(50000), // $500
    );

    final normalOverview = CategoryBudgetOverview(
      budget: normalBudget,
      category: testCategory,
      spentAmount: const Money(20000), // $200 (40%)
    );

    final overBudget = Budget(
      id: 'b-2',
      categoryId: testCategory.id,
      year: 2026,
      month: 5,
      limitAmount: const Money(10000), // $100
    );

    final overBudgetOverview = CategoryBudgetOverview(
      budget: overBudget,
      category: testCategory,
      spentAmount: const Money(15000), // $150 (150%)
    );

    setUp(() {
      budgetsCubit = MockBudgetsCubit();
      categoriesCubit = MockCategoriesCubit();

      when(() => categoriesCubit.state).thenReturn(
        CategoriesLoaded(categories: [testCategory]),
      );
    });

    Widget buildTestWidget() {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        home: MultiBlocProvider(
          providers: [
            BlocProvider<BudgetsCubit>.value(value: budgetsCubit),
            BlocProvider<CategoriesCubit>.value(value: categoriesCubit),
          ],
          child: const BudgetsPage(),
        ),
      );
    }

    testWidgets('renders month switcher and navigates between months', (tester) async {
      when(() => budgetsCubit.state).thenReturn(
        BudgetsLoaded(
          year: 2026,
          month: 5,
          budgets: [normalOverview],
        ),
      );

      await tester.pumpWidget(buildTestWidget());

      expect(find.text('May 2026'), findsOneWidget);

      await tester.tap(find.byTooltip('Previous Month'));
      verify(() => budgetsCubit.previousMonth()).called(1);

      await tester.tap(find.byTooltip('Next Month'));
      verify(() => budgetsCubit.nextMonth()).called(1);
    });

    testWidgets('renders overview banner with totals and category progress card', (tester) async {
      when(() => budgetsCubit.state).thenReturn(
        BudgetsLoaded(
          year: 2026,
          month: 5,
          budgets: [normalOverview],
        ),
      );

      await tester.pumpWidget(buildTestWidget());

      // Banner checks
      expect(find.text('Total Budgeted'), findsOneWidget);
      expect(find.text(r'$500.00'), findsAtLeastNWidgets(1));
      expect(find.text('Total Spent'), findsOneWidget);
      expect(find.text(r'$200.00'), findsAtLeastNWidgets(1));
      expect(find.text('Remaining'), findsOneWidget);
      expect(find.text(r'$300.00'), findsAtLeastNWidgets(1));

      // Category card checks
      expect(find.text('Groceries'), findsOneWidget);
      expect(find.text('40%'), findsOneWidget);
      expect(find.text('Remaining: \$300.00'), findsOneWidget);
    });

    testWidgets('renders visual warning tag when category is over budget', (tester) async {
      when(() => budgetsCubit.state).thenReturn(
        BudgetsLoaded(
          year: 2026,
          month: 5,
          budgets: [overBudgetOverview],
        ),
      );

      await tester.pumpWidget(buildTestWidget());

      expect(find.text('Over Budget'), findsAtLeastNWidgets(1));
      expect(find.text('Over by \$50.00'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('tapping category card opens edit budget sheet', (tester) async {
      when(() => budgetsCubit.state).thenReturn(
        BudgetsLoaded(
          year: 2026,
          month: 5,
          budgets: [normalOverview],
        ),
      );

      await tester.pumpWidget(buildTestWidget());

      await tester.tap(find.text('Groceries'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Category Budget'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('tapping header action button opens set budget sheet', (tester) async {
      when(() => budgetsCubit.state).thenReturn(
        const BudgetsLoaded(
          year: 2026,
          month: 5,
          budgets: [],
        ),
      );

      await tester.pumpWidget(buildTestWidget());

      await tester.tap(find.byTooltip('Set Category Budget'));
      await tester.pumpAndSettle();

      expect(find.text('Set Category Budget'), findsOneWidget);
      expect(find.text('Set Budget'), findsOneWidget);
    });

    testWidgets('when budgets exist, section header Add Budget button is visible and opens set budget sheet', (tester) async {
      when(() => budgetsCubit.state).thenReturn(
        BudgetsLoaded(
          year: 2026,
          month: 5,
          budgets: [normalOverview],
        ),
      );

      await tester.pumpWidget(buildTestWidget());

      expect(find.text('Category Budgets'), findsOneWidget);
      expect(find.text('Add Budget'), findsOneWidget);

      await tester.tap(find.text('Add Budget'));
      await tester.pumpAndSettle();

      expect(find.text('Set Category Budget'), findsOneWidget);
      expect(find.text('Set Budget'), findsOneWidget);
    });

    testWidgets('when all categories are already budgeted, SetBudgetSheet shows informative depletion message', (tester) async {
      when(() => budgetsCubit.state).thenReturn(
        BudgetsLoaded(
          year: 2026,
          month: 5,
          budgets: [normalOverview],
        ),
      );

      await tester.pumpWidget(buildTestWidget());

      await tester.tap(find.text('Add Budget'));
      await tester.pumpAndSettle();

      // In this test setup, testCategory ('cat-groceries') is the only category in categoriesCubit.
      // Since normalOverview already budgets 'cat-groceries', all categories are budgeted.
      expect(find.text('All expense categories currently have an active budget for this month.'), findsOneWidget);
    });
  });
}
