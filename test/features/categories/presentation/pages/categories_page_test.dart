import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_budget_tracker/core/theme/app_theme.dart';
import 'package:my_budget_tracker/features/categories/domain/entities/category.dart';
import 'package:my_budget_tracker/features/categories/presentation/cubit/categories_cubit.dart';
import 'package:my_budget_tracker/features/categories/presentation/cubit/categories_state.dart';
import 'package:my_budget_tracker/features/categories/presentation/pages/categories_page.dart';

class MockCategoriesCubit extends MockCubit<CategoriesState> implements CategoriesCubit {}

void main() {
  group('CategoriesPage Widget Tests', () {
    late CategoriesCubit categoriesCubit;

    final defaultCategory = Category(
      id: 'cat-groceries',
      name: 'Groceries',
      type: CategoryType.expense,
      icon: 'shopping_cart',
      color: 0xFF10B981,
      isDefault: true,
    );

    final customCategory = Category(
      id: 'cat-books',
      name: 'Books & Courses',
      type: CategoryType.expense,
      icon: 'menu_book',
      color: 0xFF8B5CF6,
      isDefault: false,
    );

    setUp(() {
      categoriesCubit = MockCategoriesCubit();
    });

    Widget buildTestWidget() {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        home: BlocProvider<CategoriesCubit>.value(
          value: categoriesCubit,
          child: const CategoriesPage(),
        ),
      );
    }

    testWidgets('renders categories with edit and delete options for all categories', (tester) async {
      when(() => categoriesCubit.state).thenReturn(
        CategoriesLoaded(categories: [defaultCategory, customCategory]),
      );

      await tester.pumpWidget(buildTestWidget());

      expect(find.text('Groceries'), findsOneWidget);
      expect(find.text('Books & Courses'), findsOneWidget);
      expect(find.byIcon(Icons.edit_outlined), findsNWidgets(2));
      expect(find.byIcon(Icons.delete_outline), findsNWidgets(2));
    });

    testWidgets('shows delete confirmation dialog when deleting default category', (tester) async {
      when(() => categoriesCubit.state).thenReturn(
        CategoriesLoaded(categories: [defaultCategory]),
      );

      await tester.pumpWidget(buildTestWidget());

      final deleteBtn = find.byIcon(Icons.delete_outline);
      expect(deleteBtn, findsOneWidget);

      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      expect(find.text('Delete Category?'), findsOneWidget);
      expect(find.text('Are you sure you want to delete "Groceries"?'), findsOneWidget);
    });

    testWidgets('shows delete confirmation dialog when deleting custom category', (tester) async {
      when(() => categoriesCubit.state).thenReturn(
        CategoriesLoaded(categories: [customCategory]),
      );

      await tester.pumpWidget(buildTestWidget());

      final deleteBtn = find.byIcon(Icons.delete_outline);
      expect(deleteBtn, findsOneWidget);

      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      expect(find.text('Delete Category?'), findsOneWidget);
      expect(find.text('Are you sure you want to delete "Books & Courses"?'), findsOneWidget);
    });

    testWidgets('opens category creation dialog on FAB tap', (tester) async {
      when(() => categoriesCubit.state).thenReturn(
        const CategoriesLoaded(categories: []),
      );

      await tester.pumpWidget(buildTestWidget());

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('New Category'), findsOneWidget);
      expect(find.text('Category Name'), findsOneWidget);
      expect(find.text('Create'), findsOneWidget);
    });
  });
}
