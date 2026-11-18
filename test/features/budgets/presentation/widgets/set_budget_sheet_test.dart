import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_budget_tracker/core/presentation/components/app_bottom_sheet.dart';
import 'package:my_budget_tracker/core/presentation/components/money_input_field.dart';
import 'package:my_budget_tracker/core/theme/app_theme.dart';
import 'package:my_budget_tracker/core/value_objects/money.dart';
import 'package:my_budget_tracker/features/budgets/domain/entities/budget.dart';
import 'package:my_budget_tracker/features/budgets/domain/entities/category_budget_overview.dart';
import 'package:my_budget_tracker/features/budgets/presentation/cubit/budgets_cubit.dart';
import 'package:my_budget_tracker/features/budgets/presentation/widgets/set_budget_sheet.dart';
import 'package:my_budget_tracker/features/categories/domain/entities/category.dart';
import 'package:my_budget_tracker/features/categories/presentation/cubit/categories_cubit.dart';
import 'package:my_budget_tracker/features/categories/presentation/cubit/categories_state.dart';

import 'package:my_budget_tracker/features/budgets/presentation/cubit/budgets_state.dart';

class MockBudgetsCubit extends MockCubit<BudgetsState> implements BudgetsCubit {}
class MockCategoriesCubit extends MockCubit<CategoriesState> implements CategoriesCubit {}

void main() {
  group('SetBudgetSheet Widget Tests', () {
    late BudgetsCubit budgetsCubit;
    late CategoriesCubit categoriesCubit;

    final expenseCat = Category(
      id: 'cat-groceries',
      name: 'Groceries',
      type: CategoryType.expense,
      icon: 'shopping_cart',
      color: 0xFF10B981,
    );

    final overview = CategoryBudgetOverview(
      budget: const Budget(
        id: 'budget-1',
        categoryId: 'cat-groceries',
        limitAmount: Money(30000),
        year: 2026,
        month: 5,
      ),
      category: expenseCat,
      spentAmount: const Money(15000),
    );

    setUp(() {
      budgetsCubit = MockBudgetsCubit();
      categoriesCubit = MockCategoriesCubit();

      when(() => categoriesCubit.state).thenReturn(
        CategoriesLoaded(categories: [expenseCat]),
      );
    });

    Widget buildTestWidget({CategoryBudgetOverview? existingOverview}) {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: MultiBlocProvider(
            providers: [
              BlocProvider<BudgetsCubit>.value(value: budgetsCubit),
              BlocProvider<CategoriesCubit>.value(value: categoriesCubit),
            ],
            child: SetBudgetSheet(
              year: 2026,
              month: 5,
              existingOverview: existingOverview,
            ),
          ),
        ),
      );
    }

    testWidgets('renders AppBottomSheet with MoneyInputField in create mode', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.byType(AppBottomSheet), findsOneWidget);
      expect(find.byType(MoneyInputField), findsOneWidget);
      expect(find.text('Set Category Budget'), findsOneWidget);
      expect(find.text('Set Budget'), findsOneWidget);
    });

    testWidgets('renders AppBottomSheet with MoneyInputField and Delete button in edit mode', (tester) async {
      await tester.pumpWidget(buildTestWidget(existingOverview: overview));

      expect(find.byType(AppBottomSheet), findsOneWidget);
      expect(find.byType(MoneyInputField), findsOneWidget);
      expect(find.text('Edit Category Budget'), findsOneWidget);
      expect(find.text('300.00'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });
  });
}
