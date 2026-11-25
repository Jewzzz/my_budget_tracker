import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_tracker/core/database/app_database.dart';
import 'package:my_budget_tracker/core/value_objects/money.dart';
import 'package:my_budget_tracker/features/accounts/data/repositories/account_repository_impl.dart';
import 'package:my_budget_tracker/features/accounts/domain/entities/account.dart';
import 'package:my_budget_tracker/features/budgets/data/repositories/budget_repository_impl.dart';
import 'package:my_budget_tracker/features/budgets/domain/entities/budget.dart';
import 'package:my_budget_tracker/features/categories/data/repositories/category_repository_impl.dart';
import 'package:my_budget_tracker/features/categories/domain/entities/category.dart';
import 'package:my_budget_tracker/features/currency/data/repositories/currency_repository_impl.dart';
import 'package:my_budget_tracker/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:my_budget_tracker/features/transactions/domain/entities/transaction.dart';
import '../../../../helpers/fake_flutter_secure_storage.dart';

void main() {
  group('BudgetRepositoryImpl Integration Tests', () {
    late AppDatabase database;
    late CategoryRepositoryImpl categoryRepository;
    late AccountRepositoryImpl accountRepository;
    late TransactionRepositoryImpl transactionRepository;
    late CurrencyRepositoryImpl currencyRepository;
    late BudgetRepositoryImpl budgetRepository;

    late Category groceriesCategory;
    late Account testAccount;

    setUp(() async {
      database = AppDatabase.inMemory();
      await database.seedDefaultCategoriesIfEmpty();
      categoryRepository = CategoryRepositoryImpl(database);
      accountRepository = AccountRepositoryImpl(database);
      transactionRepository = TransactionRepositoryImpl(database);
      currencyRepository = CurrencyRepositoryImpl(
        database: database,
        secureStorage: createInMemorySecureStorage(),
      );
      budgetRepository = BudgetRepositoryImpl(database, currencyRepository: currencyRepository);

      final categories = await categoryRepository.getCategories(type: CategoryType.expense);
      groceriesCategory = categories.firstWhere((c) => c.name == 'Groceries');

      testAccount = Account(
        id: 'acc-checking',
        name: 'Checking',
        type: AccountType.checking,
        initialBalance: const Money(100000), // $1000
        currentBalance: const Money(100000),
        icon: 'account_balance',
        color: 0xFF1E3A8A,
        createdAt: DateTime.utc(2026, 1, 1),
      );
      await accountRepository.createAccount(testAccount);
    });

    tearDown(() async {
      await database.close();
    });

    test('sets and retrieves budget for a category in a specific year and month', () async {
      final budget = Budget(
        id: 'budget-1',
        categoryId: groceriesCategory.id,
        year: 2026,
        month: 5,
        limitAmount: const Money(50000), // $500.00
      );

      await budgetRepository.setBudget(budget);

      final budgets = await budgetRepository.getBudgets(2026, 5);
      expect(budgets.length, 1);
      expect(budgets.first.categoryId, groceriesCategory.id);
      expect(budgets.first.limitAmount, const Money(50000));
      expect(budgets.first.year, 2026);
      expect(budgets.first.month, 5);
    });

    test('upserts budget limit when budget already exists for category, year, and month', () async {
      final initialBudget = Budget(
        id: 'budget-1',
        categoryId: groceriesCategory.id,
        year: 2026,
        month: 5,
        limitAmount: const Money(40000), // $400.00
      );
      await budgetRepository.setBudget(initialBudget);

      // Same category, year, and month, but different limit and ID
      final updatedBudget = Budget(
        id: 'budget-2',
        categoryId: groceriesCategory.id,
        year: 2026,
        month: 5,
        limitAmount: const Money(60000), // $600.00
      );
      await budgetRepository.setBudget(updatedBudget);

      final budgets = await budgetRepository.getBudgets(2026, 5);
      // Must not create duplicate row; updates existing
      expect(budgets.length, 1);
      expect(budgets.first.limitAmount, const Money(60000));
    });

    test('computes category spent strictly within calendar month boundaries', () async {
      final budget = Budget(
        id: 'budget-may',
        categoryId: groceriesCategory.id,
        year: 2026,
        month: 5,
        limitAmount: const Money(50000), // $500.00
      );
      await budgetRepository.setBudget(budget);

      // Expense inside May 2026: $150.00 (15000)
      await transactionRepository.createTransaction(
        Transaction(
          id: 'txn-may-1',
          accountId: testAccount.id,
          type: TransactionType.expense,
          amount: const Money(15000),
          categoryId: groceriesCategory.id,
          date: DateTime.utc(2026, 5, 10, 14, 0),
          createdAt: DateTime.utc(2026, 5, 10, 14, 0),
        ),
      );

      // Second expense inside May 2026: $50.00 (5000)
      await transactionRepository.createTransaction(
        Transaction(
          id: 'txn-may-2',
          accountId: testAccount.id,
          type: TransactionType.expense,
          amount: const Money(5000),
          categoryId: groceriesCategory.id,
          date: DateTime.utc(2026, 5, 25, 18, 0),
          createdAt: DateTime.utc(2026, 5, 25, 18, 0),
        ),
      );

      // Expense in April 2026 (previous month): $100.00 - should NOT count
      await transactionRepository.createTransaction(
        Transaction(
          id: 'txn-apr-1',
          accountId: testAccount.id,
          type: TransactionType.expense,
          amount: const Money(10000),
          categoryId: groceriesCategory.id,
          date: DateTime.utc(2026, 4, 28),
          createdAt: DateTime.utc(2026, 4, 28),
        ),
      );

      // Expense in June 2026 (next month): $200.00 - should NOT count
      await transactionRepository.createTransaction(
        Transaction(
          id: 'txn-jun-1',
          accountId: testAccount.id,
          type: TransactionType.expense,
          amount: const Money(20000),
          categoryId: groceriesCategory.id,
          date: DateTime.utc(2026, 6, 2),
          createdAt: DateTime.utc(2026, 6, 2),
        ),
      );

      final overviews = await budgetRepository.getBudgetOverviews(2026, 5);
      expect(overviews.length, 1);
      final overview = overviews.first;

      expect(overview.budget.limitAmount, const Money(50000));
      expect(overview.spentAmount, const Money(20000)); // $150 + $50 = $200
      expect(overview.remainingAmount, const Money(30000)); // $500 - $200 = $300
      expect(overview.isOverBudget, isFalse);
      expect(overview.percentageSpent, 0.4); // 40%
    });

    test('detects over-budget status when spending exceeds limit amount', () async {
      final budget = Budget(
        id: 'budget-may',
        categoryId: groceriesCategory.id,
        year: 2026,
        month: 5,
        limitAmount: const Money(10000), // $100.00 limit
      );
      await budgetRepository.setBudget(budget);

      // Spend $125.00 (12500)
      await transactionRepository.createTransaction(
        Transaction(
          id: 'txn-over',
          accountId: testAccount.id,
          type: TransactionType.expense,
          amount: const Money(12500),
          categoryId: groceriesCategory.id,
          date: DateTime.utc(2026, 5, 12),
          createdAt: DateTime.utc(2026, 5, 12),
        ),
      );

      final overviews = await budgetRepository.getBudgetOverviews(2026, 5);
      expect(overviews.length, 1);
      final overview = overviews.first;

      expect(overview.spentAmount, const Money(12500));
      expect(overview.remainingAmount, const Money(-2500)); // -$25.00
      expect(overview.isOverBudget, isTrue);
      expect(overview.percentageSpent, 1.25); // 125%
    });

    test('deletes budget by id', () async {
      final budget = Budget(
        id: 'budget-del',
        categoryId: groceriesCategory.id,
        year: 2026,
        month: 5,
        limitAmount: const Money(50000),
      );
      await budgetRepository.setBudget(budget);

      await budgetRepository.deleteBudget(budget.id);

      final budgets = await budgetRepository.getBudgets(2026, 5);
      expect(budgets, isEmpty);
    });

    test('supports creating multiple distinct category budgets simultaneously in the same month', () async {
      final categories = await categoryRepository.getCategories(type: CategoryType.expense);
      final transportCategory = categories.firstWhere((c) => c.name == 'Transport');
      final utilitiesCategory = categories.firstWhere((c) => c.name == 'Utilities');

      final b1 = Budget(
        id: 'b-groceries',
        categoryId: groceriesCategory.id,
        year: 2026,
        month: 5,
        limitAmount: const Money(50000), // $500
      );
      final b2 = Budget(
        id: 'b-transport',
        categoryId: transportCategory.id,
        year: 2026,
        month: 5,
        limitAmount: const Money(20000), // $200
      );
      final b3 = Budget(
        id: 'b-utilities',
        categoryId: utilitiesCategory.id,
        year: 2026,
        month: 5,
        limitAmount: const Money(15000), // $150
      );

      await budgetRepository.setBudget(b1);
      await budgetRepository.setBudget(b2);
      await budgetRepository.setBudget(b3);

      final budgets = await budgetRepository.getBudgets(2026, 5);
      expect(budgets.length, 3);

      final overviews = await budgetRepository.getBudgetOverviews(2026, 5);
      expect(overviews.length, 3);
      expect(overviews.map((o) => o.category.id), containsAll([groceriesCategory.id, transportCategory.id, utilitiesCategory.id]));
    });

    test('tracks spending independently across multiple category budgets and ignores unbudgeted categories', () async {
      final categories = await categoryRepository.getCategories(type: CategoryType.expense);
      final transportCategory = categories.firstWhere((c) => c.name == 'Transport');
      final healthcareCategory = categories.firstWhere((c) => c.name == 'Healthcare');

      await budgetRepository.setBudget(
        Budget(
          id: 'b-groc',
          categoryId: groceriesCategory.id,
          year: 2026,
          month: 5,
          limitAmount: const Money(50000), // $500
        ),
      );
      await budgetRepository.setBudget(
        Budget(
          id: 'b-trans',
          categoryId: transportCategory.id,
          year: 2026,
          month: 5,
          limitAmount: const Money(20000), // $200
        ),
      );

      // Expense 1: Groceries ($120)
      await transactionRepository.createTransaction(
        Transaction(
          id: 'txn-groc-1',
          accountId: testAccount.id,
          type: TransactionType.expense,
          amount: const Money(12000),
          categoryId: groceriesCategory.id,
          date: DateTime.utc(2026, 5, 4),
          createdAt: DateTime.utc(2026, 5, 4),
        ),
      );

      // Expense 2: Transport ($80)
      await transactionRepository.createTransaction(
        Transaction(
          id: 'txn-trans-1',
          accountId: testAccount.id,
          type: TransactionType.expense,
          amount: const Money(8000),
          categoryId: transportCategory.id,
          date: DateTime.utc(2026, 5, 8),
          createdAt: DateTime.utc(2026, 5, 8),
        ),
      );

      // Expense 3: Healthcare (Unbudgeted, $99)
      await transactionRepository.createTransaction(
        Transaction(
          id: 'txn-health-1',
          accountId: testAccount.id,
          type: TransactionType.expense,
          amount: const Money(9900),
          categoryId: healthcareCategory.id,
          date: DateTime.utc(2026, 5, 15),
          createdAt: DateTime.utc(2026, 5, 15),
        ),
      );

      final overviews = await budgetRepository.getBudgetOverviews(2026, 5);
      expect(overviews.length, 2);

      final grocOverview = overviews.firstWhere((o) => o.category.id == groceriesCategory.id);
      expect(grocOverview.spentAmount, const Money(12000));
      expect(grocOverview.remainingAmount, const Money(38000));
      expect(grocOverview.isOverBudget, isFalse);

      final transOverview = overviews.firstWhere((o) => o.category.id == transportCategory.id);
      expect(transOverview.spentAmount, const Money(8000));
      expect(transOverview.remainingAmount, const Money(12000));
      expect(transOverview.isOverBudget, isFalse);
    });

    test('deleting one category budget leaves other category budgets intact', () async {
      final categories = await categoryRepository.getCategories(type: CategoryType.expense);
      final transportCategory = categories.firstWhere((c) => c.name == 'Transport');

      await budgetRepository.setBudget(
        Budget(
          id: 'b-groc',
          categoryId: groceriesCategory.id,
          year: 2026,
          month: 5,
          limitAmount: const Money(50000),
        ),
      );
      await budgetRepository.setBudget(
        Budget(
          id: 'b-trans',
          categoryId: transportCategory.id,
          year: 2026,
          month: 5,
          limitAmount: const Money(20000),
        ),
      );

      await budgetRepository.deleteBudget('b-trans');

      final overviews = await budgetRepository.getBudgetOverviews(2026, 5);
      expect(overviews.length, 1);
      expect(overviews.first.category.id, groceriesCategory.id);
      expect(overviews.first.budget.limitAmount, const Money(50000));
    });

    test('multi-currency budgeting: converts foreign expenses and accumulates to budget', () async {
      // 1. Budget of $100.00 USD for Groceries
      await budgetRepository.setBudget(
        Budget(
          id: 'b-groc-multi',
          categoryId: groceriesCategory.id,
          year: 2026,
          month: 5,
          limitAmount: const Money(10000, 'USD'),
        ),
      );

      // 2. Foreign currency expense: €50 EUR (5000 cents) settled as $55.00 USD (5500 cents) on USD account
      await transactionRepository.createTransaction(
        Transaction(
          id: 'txn-eur-exp',
          accountId: testAccount.id,
          type: TransactionType.expense,
          amount: const Money(5500, 'USD'), // Settled in USD
          originalAmount: const Money(5000, 'EUR'), // Foreign €50.00
          exchangeRateScaled: 110000000, // 1.10 rate
          categoryId: groceriesCategory.id,
          date: DateTime.utc(2026, 5, 10),
          createdAt: DateTime.utc(2026, 5, 10),
        ),
      );

      // 3. Foreign currency expense on EUR account: €20 EUR (2000 cents)
      final eurAccount = Account(
        id: 'acc-eur',
        name: 'Euro Travel',
        type: AccountType.checking,
        currencyCode: 'EUR',
        initialBalance: const Money(50000, 'EUR'), // €500.00
        currentBalance: const Money(50000, 'EUR'),
        isArchived: false,
        icon: 'euro',
        color: 0xFF2563EB,
        createdAt: DateTime.utc(2026, 1, 1),
      );
      await accountRepository.createAccount(eurAccount);

      // Seed rate: EUR -> USD: 108695652 (~1.086956)
      // €20.00 EUR -> USD at 1.086956: 2000 * 108695652 * 100 ~/ (10^8 * 100) = 2174 cents ($21.74)
      await transactionRepository.createTransaction(
        Transaction(
          id: 'txn-eur-direct',
          accountId: eurAccount.id,
          type: TransactionType.expense,
          amount: const Money(2000, 'EUR'), // Settled in EUR
          categoryId: groceriesCategory.id,
          date: DateTime.utc(2026, 5, 15),
          createdAt: DateTime.utc(2026, 5, 15),
        ),
      );

      final overviews = await budgetRepository.getBudgetOverviews(2026, 5);
      expect(overviews.length, 1);
      final overview = overviews.first;

      // Spent: $55.00 + $21.74 = $76.74 (7674 cents)
      expect(overview.spentAmount.currencyCode, 'USD');
      expect(overview.spentAmount.minorUnits, 7674);
      expect(overview.remainingAmount.currencyCode, 'USD');
      expect(overview.remainingAmount.minorUnits, 2326); // $100.00 - $76.74 = $23.26
      expect(overview.isOverBudget, isFalse);
    });
  });
}
