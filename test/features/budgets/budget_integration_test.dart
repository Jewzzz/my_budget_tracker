import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_tracker/core/database/app_database.dart';
import 'package:my_budget_tracker/core/value_objects/money.dart';
import 'package:my_budget_tracker/features/accounts/data/repositories/account_repository_impl.dart';
import 'package:my_budget_tracker/features/accounts/domain/entities/account.dart';
import 'package:my_budget_tracker/features/budgets/data/repositories/budget_repository_impl.dart';
import 'package:my_budget_tracker/features/budgets/domain/entities/budget.dart';
import 'package:my_budget_tracker/features/categories/data/repositories/category_repository_impl.dart';
import 'package:my_budget_tracker/features/categories/domain/entities/category.dart';
import 'package:my_budget_tracker/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:my_budget_tracker/features/transactions/domain/entities/transaction.dart';

void main() {
  group('Budget End-to-End Integration Tests', () {
    late AppDatabase database;
    late CategoryRepositoryImpl categoryRepository;
    late AccountRepositoryImpl accountRepository;
    late TransactionRepositoryImpl transactionRepository;
    late BudgetRepositoryImpl budgetRepository;

    late Category diningCategory;
    late Account checkingAccount;

    setUp(() async {
      database = AppDatabase.inMemory();
      await database.seedDefaultCategoriesIfEmpty();
      categoryRepository = CategoryRepositoryImpl(database);
      accountRepository = AccountRepositoryImpl(database);
      transactionRepository = TransactionRepositoryImpl(database);
      budgetRepository = BudgetRepositoryImpl(database);

      final categories = await categoryRepository.getCategories(type: CategoryType.expense);
      diningCategory = categories.firstWhere((c) => c.name == 'Dining');

      checkingAccount = Account(
        id: 'acc-e2e',
        name: 'Checking',
        type: AccountType.checking,
        initialBalance: const Money(200000), // $2000
        currentBalance: const Money(200000),
        icon: 'account_balance',
        color: 0xFF1E3A8A,
        createdAt: DateTime.utc(2026, 1, 1),
      );
      await accountRepository.createAccount(checkingAccount);
    });

    tearDown(() async {
      await database.close();
    });

    test('logging expenses updates budget consumption and triggers over-budget status without cascading into next month', () async {
      // 1. Set May 2026 Dining budget: $200.00 (20000 minor units)
      final mayBudget = Budget(
        id: 'budget-may-dining',
        categoryId: diningCategory.id,
        year: 2026,
        month: 5,
        limitAmount: const Money(20000),
      );
      await budgetRepository.setBudget(mayBudget);

      // 2. Set June 2026 Dining budget: $200.00 (20000 minor units)
      final juneBudget = Budget(
        id: 'budget-june-dining',
        categoryId: diningCategory.id,
        year: 2026,
        month: 6,
        limitAmount: const Money(20000),
      );
      await budgetRepository.setBudget(juneBudget);

      // Verify initial May state (0% spent)
      var mayOverviews = await budgetRepository.getBudgetOverviews(2026, 5);
      expect(mayOverviews.first.spentAmount, Money.zero);
      expect(mayOverviews.first.remainingAmount, const Money(20000));
      expect(mayOverviews.first.isOverBudget, isFalse);

      // 3. Log an expense of $120.00 (12000) on May 5, 2026
      await transactionRepository.createTransaction(
        Transaction(
          id: 'txn-may-exp1',
          accountId: checkingAccount.id,
          type: TransactionType.expense,
          amount: const Money(12000),
          categoryId: diningCategory.id,
          date: DateTime.utc(2026, 5, 5),
          createdAt: DateTime.utc(2026, 5, 5),
        ),
      );

      // Verify May state: 60% spent
      mayOverviews = await budgetRepository.getBudgetOverviews(2026, 5);
      expect(mayOverviews.first.spentAmount, const Money(12000));
      expect(mayOverviews.first.remainingAmount, const Money(8000));
      expect(mayOverviews.first.percentageSpent, 0.6);
      expect(mayOverviews.first.isOverBudget, isFalse);

      // 4. Log an additional expense of $100.00 (10000) on May 20, 2026 -> Total May spend: $220.00
      await transactionRepository.createTransaction(
        Transaction(
          id: 'txn-may-exp2',
          accountId: checkingAccount.id,
          type: TransactionType.expense,
          amount: const Money(10000),
          categoryId: diningCategory.id,
          date: DateTime.utc(2026, 5, 20),
          createdAt: DateTime.utc(2026, 5, 20),
        ),
      );

      // Verify May state is now OVER BUDGET:
      mayOverviews = await budgetRepository.getBudgetOverviews(2026, 5);
      expect(mayOverviews.first.spentAmount, const Money(22000));
      expect(mayOverviews.first.remainingAmount, const Money(-2000));
      expect(mayOverviews.first.percentageSpent, 1.1); // 110%
      expect(mayOverviews.first.isOverBudget, isTrue);

      // 5. Verify June 2026 budget is NOT affected (no cascading negative debt)
      final juneOverviews = await budgetRepository.getBudgetOverviews(2026, 6);
      expect(juneOverviews.first.spentAmount, Money.zero);
      expect(juneOverviews.first.remainingAmount, const Money(20000));
      expect(juneOverviews.first.isOverBudget, isFalse);
    });

    test('supports multiple category budgets concurrently with independent calculations and alerts', () async {
      final categories = await categoryRepository.getCategories(type: CategoryType.expense);
      final groceriesCat = categories.firstWhere((c) => c.name == 'Groceries');
      final transportCat = categories.firstWhere((c) => c.name == 'Transport');

      // 1. Create budgets for Groceries ($300) and Transport ($100) in July 2026
      await budgetRepository.setBudget(
        Budget(
          id: 'b-july-groc',
          categoryId: groceriesCat.id,
          year: 2026,
          month: 7,
          limitAmount: const Money(30000),
        ),
      );
      await budgetRepository.setBudget(
        Budget(
          id: 'b-july-trans',
          categoryId: transportCat.id,
          year: 2026,
          month: 7,
          limitAmount: const Money(10000),
        ),
      );

      // Verify both present and 0% spent
      var overviews = await budgetRepository.getBudgetOverviews(2026, 7);
      expect(overviews.length, 2);
      expect(overviews.map((o) => o.category.id), containsAll([groceriesCat.id, transportCat.id]));

      // 2. Spend $250 on Groceries (normal, 83%), and $120 on Transport (over budget, 120%)
      await transactionRepository.createTransaction(
        Transaction(
          id: 'txn-july-groc',
          accountId: checkingAccount.id,
          type: TransactionType.expense,
          amount: const Money(25000),
          categoryId: groceriesCat.id,
          date: DateTime.utc(2026, 7, 10),
          createdAt: DateTime.utc(2026, 7, 10),
        ),
      );
      await transactionRepository.createTransaction(
        Transaction(
          id: 'txn-july-trans',
          accountId: checkingAccount.id,
          type: TransactionType.expense,
          amount: const Money(12000),
          categoryId: transportCat.id,
          date: DateTime.utc(2026, 7, 12),
          createdAt: DateTime.utc(2026, 7, 12),
        ),
      );

      overviews = await budgetRepository.getBudgetOverviews(2026, 7);
      final groc = overviews.firstWhere((o) => o.category.id == groceriesCat.id);
      final trans = overviews.firstWhere((o) => o.category.id == transportCat.id);

      expect(groc.spentAmount, const Money(25000));
      expect(groc.remainingAmount, const Money(5000));
      expect(groc.isOverBudget, isFalse);

      expect(trans.spentAmount, const Money(12000));
      expect(trans.remainingAmount, const Money(-2000));
      expect(trans.isOverBudget, isTrue);

      // 3. Edit Groceries budget limit to $400
      await budgetRepository.setBudget(
        Budget(
          id: 'b-july-groc-updated',
          categoryId: groceriesCat.id,
          year: 2026,
          month: 7,
          limitAmount: const Money(40000),
        ),
      );

      overviews = await budgetRepository.getBudgetOverviews(2026, 7);
      final grocUpdated = overviews.firstWhere((o) => o.category.id == groceriesCat.id);
      final transUnchanged = overviews.firstWhere((o) => o.category.id == transportCat.id);

      expect(grocUpdated.budget.limitAmount, const Money(40000));
      expect(grocUpdated.remainingAmount, const Money(15000));

      expect(transUnchanged.budget.limitAmount, const Money(10000));
      expect(transUnchanged.remainingAmount, const Money(-2000));
      expect(transUnchanged.isOverBudget, isTrue);
    });
  });
}
