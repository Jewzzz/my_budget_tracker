import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_tracker/core/database/app_database.dart';
import 'package:my_budget_tracker/core/theme/app_theme.dart';
import 'package:my_budget_tracker/core/value_objects/money.dart';
import 'package:my_budget_tracker/features/accounts/data/repositories/account_repository_impl.dart';
import 'package:my_budget_tracker/features/accounts/domain/entities/account.dart';
import 'package:my_budget_tracker/features/accounts/presentation/cubit/accounts_cubit.dart';
import 'package:my_budget_tracker/features/categories/data/repositories/category_repository_impl.dart';
import 'package:my_budget_tracker/features/categories/domain/entities/category.dart';
import 'package:my_budget_tracker/features/categories/presentation/cubit/categories_cubit.dart';
import 'package:my_budget_tracker/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:my_budget_tracker/features/transactions/presentation/cubit/transactions_cubit.dart';
import 'package:my_budget_tracker/features/transactions/presentation/cubit/transactions_state.dart';
import 'package:my_budget_tracker/features/transactions/presentation/widgets/quick_add_transaction_sheet.dart';

void main() {
  group('Category Real-Time Propagation Integration Tests', () {
    late AppDatabase database;
    late CategoryRepositoryImpl categoryRepository;
    late TransactionRepositoryImpl transactionRepository;
    late AccountRepositoryImpl accountRepository;
    late CategoriesCubit categoriesCubit;
    late TransactionsCubit transactionsCubit;
    late AccountsCubit accountsCubit;

    setUp(() async {
      database = AppDatabase.inMemory();
      await database.seedDefaultCategoriesIfEmpty();

      categoryRepository = CategoryRepositoryImpl(database);
      transactionRepository = TransactionRepositoryImpl(database);
      accountRepository = AccountRepositoryImpl(database);

      // Seed account so QuickAddTransactionSheet can render form
      await accountRepository.createAccount(
        Account(
          id: 'acc-main',
          name: 'Main Checking',
          type: AccountType.checking,
          initialBalance: const Money(100000),
          currentBalance: const Money(100000),
          icon: 'account_balance',
          color: 0xFF2196F3,
          createdAt: DateTime.now(),
        ),
      );

      categoriesCubit = CategoriesCubit(categoryRepository);
      categoriesCubit.loadCategories();

      transactionsCubit = TransactionsCubit(
        transactionRepository: transactionRepository,
        categoryRepository: categoryRepository,
      );
      transactionsCubit.loadTransactions();

      accountsCubit = AccountsCubit(accountRepository);
      accountsCubit.loadAccounts();
    });

    tearDown(() async {
      await categoriesCubit.close();
      await transactionsCubit.close();
      await accountsCubit.close();
      await database.close();
    });

    Widget buildTestApp() {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: MultiBlocProvider(
            providers: [
              BlocProvider<CategoriesCubit>.value(value: categoriesCubit),
              BlocProvider<TransactionsCubit>.value(value: transactionsCubit),
              BlocProvider<AccountsCubit>.value(value: accountsCubit),
            ],
            child: const QuickAddTransactionSheet(),
          ),
        ),
      );
    }

    testWidgets(
      'newly created categories immediately appear in Expense (Transaction) and Income sections of QuickAddTransactionSheet without app restart',
      (tester) async {
        await tester.runAsync(() async {
          await Future.delayed(const Duration(milliseconds: 50));
        });
        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        // 1. Verify initial categories do not contain our new test categories
        final initialLoaded = transactionsCubit.state as TransactionsLoaded;
        expect(initialLoaded.categories.any((c) => c.name == 'Snowboarding'), isFalse);
        expect(initialLoaded.categories.any((c) => c.name == 'Crypto Staking'), isFalse);

        // 2. Create a new custom Expense category via CategoriesCubit
        const newExpenseCat = Category(
          id: 'cat-snowboarding',
          name: 'Snowboarding',
          type: CategoryType.expense,
          icon: 'downhill_skiing',
          color: 0xFF00BCD4,
          isDefault: false,
        );
        await categoriesCubit.createCategory(newExpenseCat);
        await tester.runAsync(() async {
          await Future.delayed(const Duration(milliseconds: 50));
        });
        await tester.pumpAndSettle();

        // Verify that TransactionsCubit state received the new category in real time
        final stateAfterExpense = transactionsCubit.state as TransactionsLoaded;
        expect(
          stateAfterExpense.categories.any((c) => c.name == 'Snowboarding'),
          isTrue,
          reason: 'TransactionsCubit must reactively receive the new Expense category from watchCategories',
        );

        // Verify QuickAddTransactionSheet Expense Category picker contains "Snowboarding"
        // Tap category dropdown to open options
        final categoryDropdown = find.byType(DropdownButtonFormField<String>).last;
        await tester.tap(categoryDropdown);
        await tester.pumpAndSettle();

        expect(find.text('Snowboarding').last, findsOneWidget);

        // Close dropdown
        await tester.tap(find.text('Snowboarding').last);
        await tester.pumpAndSettle();

        // 3. Create a new custom Income category via CategoriesCubit
        const newIncomeCat = Category(
          id: 'cat-crypto-staking',
          name: 'Crypto Staking',
          type: CategoryType.income,
          icon: 'trending_up',
          color: 0xFF4CAF50,
          isDefault: false,
        );
        await categoriesCubit.createCategory(newIncomeCat);
        await tester.runAsync(() async {
          await Future.delayed(const Duration(milliseconds: 50));
        });
        await tester.pumpAndSettle();

        // Verify that TransactionsCubit state received the new Income category in real time
        final stateAfterIncome = transactionsCubit.state as TransactionsLoaded;
        expect(
          stateAfterIncome.categories.any((c) => c.name == 'Crypto Staking'),
          isTrue,
          reason: 'TransactionsCubit must reactively receive the new Income category from watchCategories',
        );

        // Switch to Income tab in QuickAddTransactionSheet
        await tester.tap(find.text('Income'));
        await tester.pumpAndSettle();

        // Open Category dropdown in Income tab
        final incomeCategoryDropdown = find.byType(DropdownButtonFormField<String>).last;
        await tester.tap(incomeCategoryDropdown);
        await tester.pumpAndSettle();

        expect(find.text('Crypto Staking').last, findsOneWidget);

        // Close dropdown
        await tester.tap(find.text('Crypto Staking').last);
        await tester.pumpAndSettle();

        // 4. Update the category name via CategoriesCubit and verify real-time propagation
        final updatedExpenseCat = newExpenseCat.copyWith(name: 'Alpine Skiing');
        await categoriesCubit.updateCategory(updatedExpenseCat);
        await tester.runAsync(() async {
          await Future.delayed(const Duration(milliseconds: 50));
        });
        await tester.pumpAndSettle();

        final stateAfterUpdate = transactionsCubit.state as TransactionsLoaded;
        expect(stateAfterUpdate.categories.any((c) => c.name == 'Alpine Skiing'), isTrue);
        expect(stateAfterUpdate.categories.any((c) => c.name == 'Snowboarding'), isFalse);

        // 5. Delete category via CategoriesCubit and verify real-time propagation
        await categoriesCubit.deleteCategory('cat-crypto-staking');
        await tester.runAsync(() async {
          await Future.delayed(const Duration(milliseconds: 50));
        });
        await tester.pumpAndSettle();

        final stateAfterDelete = transactionsCubit.state as TransactionsLoaded;
        expect(stateAfterDelete.categories.any((c) => c.id == 'cat-crypto-staking'), isFalse);
      },
    );
  });
}
