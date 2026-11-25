import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_tracker/core/database/app_database.dart';
import 'package:my_budget_tracker/core/value_objects/money.dart';
import 'package:my_budget_tracker/features/accounts/data/repositories/account_repository_impl.dart';
import 'package:my_budget_tracker/features/accounts/domain/entities/account.dart';
import 'package:my_budget_tracker/features/categories/data/repositories/category_repository_impl.dart';
import 'package:my_budget_tracker/features/categories/domain/entities/category.dart';
import 'package:my_budget_tracker/features/currency/data/repositories/currency_repository_impl.dart';
import 'package:my_budget_tracker/features/reports/data/repositories/reports_repository_impl.dart';
import 'package:my_budget_tracker/features/reports/domain/entities/reports_timeframe.dart';
import 'package:my_budget_tracker/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:my_budget_tracker/features/transactions/domain/entities/transaction.dart';
import '../../../../helpers/fake_flutter_secure_storage.dart';

void main() {
  group('ReportsRepositoryImpl Unit & Integration Tests', () {
    late AppDatabase database;
    late AccountRepositoryImpl accountRepository;
    late CategoryRepositoryImpl categoryRepository;
    late TransactionRepositoryImpl transactionRepository;
    late CurrencyRepositoryImpl currencyRepository;
    late ReportsRepositoryImpl reportsRepository;

    late Account checkingAccount;
    late Account savingsAccount;
    late Category salaryCategory;
    late Category groceriesCategory;
    late Category diningCategory;

    setUp(() async {
      database = AppDatabase.inMemory();
      await database.seedDefaultCategoriesIfEmpty();

      accountRepository = AccountRepositoryImpl(database);
      categoryRepository = CategoryRepositoryImpl(database);
      transactionRepository = TransactionRepositoryImpl(database);
      currencyRepository = CurrencyRepositoryImpl(
        database: database,
        secureStorage: createInMemorySecureStorage(),
      );
      reportsRepository = ReportsRepositoryImpl(database, currencyRepository: currencyRepository);

      checkingAccount = Account(
        id: 'acc-check',
        name: 'Checking',
        type: AccountType.checking,
        initialBalance: const Money(100000), // $1,000
        currentBalance: const Money(100000),
        icon: 'account_balance',
        color: 0xFF1E3A8A,
        createdAt: DateTime.utc(2026, 1, 1),
      );
      await accountRepository.createAccount(checkingAccount);

      savingsAccount = Account(
        id: 'acc-save',
        name: 'Savings',
        type: AccountType.savings,
        initialBalance: const Money(200000), // $2,000
        currentBalance: const Money(200000),
        icon: 'savings',
        color: 0xFF10B981,
        createdAt: DateTime.utc(2026, 1, 1),
      );
      await accountRepository.createAccount(savingsAccount);

      final incCats = await categoryRepository.getCategories(type: CategoryType.income);
      salaryCategory = incCats.firstWhere((c) => c.name == 'Salary');

      final expCats = await categoryRepository.getCategories(type: CategoryType.expense);
      groceriesCategory = expCats.firstWhere((c) => c.name == 'Groceries');
      diningCategory = expCats.firstWhere((c) => c.name == 'Dining');
    });

    tearDown(() async {
      await database.close();
    });

    group('Cash Flow Report', () {
      test('calculates total income, expenses, net cash flow, and savings rate excluding transfers', () async {
        // May 2026 transactions:
        // Income: $3,000
        await transactionRepository.createTransaction(
          Transaction(
            id: 'txn-inc-1',
            accountId: checkingAccount.id,
            type: TransactionType.income,
            amount: const Money(300000),
            categoryId: salaryCategory.id,
            date: DateTime(2026, 5, 2, 10),
            createdAt: DateTime(2026, 5, 2, 10),
          ),
        );

        // Expense 1: Groceries $600
        await transactionRepository.createTransaction(
          Transaction(
            id: 'txn-exp-1',
            accountId: checkingAccount.id,
            type: TransactionType.expense,
            amount: const Money(60000),
            categoryId: groceriesCategory.id,
            date: DateTime(2026, 5, 5, 12),
            createdAt: DateTime(2026, 5, 5, 12),
          ),
        );

        // Expense 2: Dining $400
        await transactionRepository.createTransaction(
          Transaction(
            id: 'txn-exp-2',
            accountId: checkingAccount.id,
            type: TransactionType.expense,
            amount: const Money(40000),
            categoryId: diningCategory.id,
            date: DateTime(2026, 5, 15, 19),
            createdAt: DateTime(2026, 5, 15, 19),
          ),
        );

        // Transfer: $500 from Checking to Savings (MUST BE EXCLUDED)
        await transactionRepository.createTransaction(
          Transaction(
            id: 'txn-trf-1',
            accountId: checkingAccount.id,
            destinationAccountId: savingsAccount.id,
            type: TransactionType.transfer,
            amount: const Money(50000),
            date: DateTime(2026, 5, 10, 14),
            createdAt: DateTime(2026, 5, 10, 14),
          ),
        );

        // Query Custom Range for May 2026
        final report = await reportsRepository.getCashFlowReport(
          ReportsTimeframe.custom,
          customStart: DateTime(2026, 5, 1),
          customEnd: DateTime(2026, 5, 31, 23, 59, 59),
        );

        // Total Income: $3,000.00
        expect(report.totalIncome, const Money(300000));
        // Total Expense: $1,000.00 ($600 + $400, transfer excluded)
        expect(report.totalExpense, const Money(100000));
        // Net Cash Flow: $3,000 - $1,000 = $2,000.00
        expect(report.netCashFlow, const Money(200000));
        // Savings Rate: ($2,000 / $3,000) * 100 = 66.67%
        expect(report.savingsRate, closeTo(66.67, 0.01));
      });

      test('safely clamps savings rate to 0.0 when income is 0 or negative cash flow', () async {
        // Only expense: $200
        await transactionRepository.createTransaction(
          Transaction(
            id: 'txn-exp-zero-inc',
            accountId: checkingAccount.id,
            type: TransactionType.expense,
            amount: const Money(20000),
            categoryId: groceriesCategory.id,
            date: DateTime(2026, 5, 5),
            createdAt: DateTime(2026, 5, 5),
          ),
        );

        final report = await reportsRepository.getCashFlowReport(
          ReportsTimeframe.custom,
          customStart: DateTime(2026, 5, 1),
          customEnd: DateTime(2026, 5, 31, 23, 59, 59),
        );

        expect(report.totalIncome, Money.zero);
        expect(report.totalExpense, const Money(20000));
        expect(report.netCashFlow, const Money(-20000));
        expect(report.savingsRate, 0.0);
      });
    });

    group('Category Breakdown Report', () {
      test('ranks spending by category and calculates percentages safely', () async {
        // Groceries: $300 (75%)
        await transactionRepository.createTransaction(
          Transaction(
            id: 'cat-exp-1',
            accountId: checkingAccount.id,
            type: TransactionType.expense,
            amount: const Money(30000),
            categoryId: groceriesCategory.id,
            date: DateTime(2026, 5, 3),
            createdAt: DateTime(2026, 5, 3),
          ),
        );

        // Dining: $100 (25%)
        await transactionRepository.createTransaction(
          Transaction(
            id: 'cat-exp-2',
            accountId: checkingAccount.id,
            type: TransactionType.expense,
            amount: const Money(10000),
            categoryId: diningCategory.id,
            date: DateTime(2026, 5, 4),
            createdAt: DateTime(2026, 5, 4),
          ),
        );

        // Transfer: $500 (MUST BE EXCLUDED)
        await transactionRepository.createTransaction(
          Transaction(
            id: 'cat-trf-1',
            accountId: checkingAccount.id,
            destinationAccountId: savingsAccount.id,
            type: TransactionType.transfer,
            amount: const Money(50000),
            date: DateTime(2026, 5, 4),
            createdAt: DateTime(2026, 5, 4),
          ),
        );

        final report = await reportsRepository.getCategoryBreakdownReport(
          ReportsTimeframe.custom,
          customStart: DateTime(2026, 5, 1),
          customEnd: DateTime(2026, 5, 31, 23, 59, 59),
        );

        expect(report.totalExpense, const Money(40000));
        expect(report.items.length, 2);

        // Ranked 1: Groceries ($300, 75%)
        expect(report.items[0].category.name, 'Groceries');
        expect(report.items[0].amount, const Money(30000));
        expect(report.items[0].percentage, closeTo(75.0, 0.01));

        // Ranked 2: Dining ($100, 25%)
        expect(report.items[1].category.name, 'Dining');
        expect(report.items[1].amount, const Money(10000));
        expect(report.items[1].percentage, closeTo(25.0, 0.01));
      });
    });

    group('Net Worth Trend Report', () {
      test('computes cumulative balances across checkpoints', () async {
        // Initial Net Worth: $1,000 (checking) + $2,000 (savings) = $3,000
        // Expense on May 10: -$400
        await transactionRepository.createTransaction(
          Transaction(
            id: 'nw-exp-1',
            accountId: checkingAccount.id,
            type: TransactionType.expense,
            amount: const Money(40000),
            categoryId: groceriesCategory.id,
            date: DateTime(2026, 5, 10),
            createdAt: DateTime(2026, 5, 10),
          ),
        );

        // Income on May 20: +$1,000
        await transactionRepository.createTransaction(
          Transaction(
            id: 'nw-inc-1',
            accountId: checkingAccount.id,
            type: TransactionType.income,
            amount: const Money(100000),
            categoryId: salaryCategory.id,
            date: DateTime(2026, 5, 20),
            createdAt: DateTime(2026, 5, 20),
          ),
        );

        final report = await reportsRepository.getNetWorthTrendReport(
          ReportsTimeframe.custom,
          customStart: DateTime(2026, 5, 1),
          customEnd: DateTime(2026, 5, 31, 23, 59, 59),
        );

        // Current Net Worth: $3,000 - $400 + $1,000 = $3,600
        expect(report.currentNetWorth, const Money(360000));
        expect(report.points.isNotEmpty, isTrue);

        // Start point (before May 10): $3,000
        final startPoint = report.points.first;
        expect(startPoint.netWorth, const Money(300000));

        // End point (after May 20): $3,600
        final endPoint = report.points.last;
        expect(endPoint.netWorth, const Money(360000));
        expect(report.netChange, const Money(60000));
      });
    });

    group('Timezone & Boundary Tests', () {
      test('strictly includes boundary timestamps and excludes outside transactions', () async {
        // Start of May 1: 2026-05-01 00:00:00
        await transactionRepository.createTransaction(
          Transaction(
            id: 'txn-bound-1',
            accountId: checkingAccount.id,
            type: TransactionType.income,
            amount: const Money(10000),
            categoryId: salaryCategory.id,
            date: DateTime(2026, 5, 1, 0, 0, 0),
            createdAt: DateTime(2026, 5, 1, 0, 0, 0),
          ),
        );

        // End of May 31: 2026-05-31 23:59:59
        await transactionRepository.createTransaction(
          Transaction(
            id: 'txn-bound-2',
            accountId: checkingAccount.id,
            type: TransactionType.income,
            amount: const Money(20000),
            categoryId: salaryCategory.id,
            date: DateTime(2026, 5, 31, 23, 59, 59),
            createdAt: DateTime(2026, 5, 31, 23, 59, 59),
          ),
        );

        // Outside: June 1 00:00:01
        await transactionRepository.createTransaction(
          Transaction(
            id: 'txn-bound-outside',
            accountId: checkingAccount.id,
            type: TransactionType.income,
            amount: const Money(50000),
            categoryId: salaryCategory.id,
            date: DateTime(2026, 6, 1, 0, 0, 1),
            createdAt: DateTime(2026, 6, 1, 0, 0, 1),
          ),
        );

        final report = await reportsRepository.getCashFlowReport(
          ReportsTimeframe.custom,
          customStart: DateTime(2026, 5, 1),
          customEnd: DateTime(2026, 5, 31),
        );

        expect(report.totalIncome, const Money(30000)); // 10000 + 20000, outside 50000 excluded
      });
    });

    group('Multi-Currency Reporting Consolidation', () {
      test('aggregates cash flow with multi-currency income and expenses converted to primary currency', () async {
        // 1. Create LKR account with native currency
        final lkrAccount = Account(
          id: 'acc-lkr',
          name: 'LKR Account',
          type: AccountType.checking,
          currencyCode: 'LKR',
          initialBalance: const Money(10000000, 'LKR'), // Rs 100,000.00
          currentBalance: const Money(10000000, 'LKR'),
          isArchived: false,
          icon: 'payments',
          color: 0xFF10B981,
          createdAt: DateTime.utc(2026, 1, 1),
        );
        await accountRepository.createAccount(lkrAccount);

        // 2. Income on USD account: $1,000 USD (100000)
        await transactionRepository.createTransaction(
          Transaction(
            id: 'tx-usd-inc',
            accountId: checkingAccount.id,
            type: TransactionType.income,
            amount: const Money(100000, 'USD'),
            categoryId: salaryCategory.id,
            date: DateTime.utc(2026, 5, 5),
            createdAt: DateTime.utc(2026, 5, 5),
          ),
        );

        // 3. Income on LKR account: Rs 300,000.00 LKR (30000000 cents).
        // Seeded rate: LKR -> USD is 333333 (~0.00333333), converts to $1,000.00 USD (100000 cents)
        await transactionRepository.createTransaction(
          Transaction(
            id: 'tx-lkr-inc',
            accountId: lkrAccount.id,
            type: TransactionType.income,
            amount: const Money(30000000, 'LKR'),
            categoryId: salaryCategory.id,
            date: DateTime.utc(2026, 5, 10),
            createdAt: DateTime.utc(2026, 5, 10),
          ),
        );

        // 4. Expense on USD account with foreign EUR expenditure: €50 EUR (settled as $55.00 USD)
        await transactionRepository.createTransaction(
          Transaction(
            id: 'tx-usd-exp-foreign',
            accountId: checkingAccount.id,
            type: TransactionType.expense,
            amount: const Money(5500, 'USD'),
            originalAmount: const Money(5000, 'EUR'),
            exchangeRateScaled: 110000000,
            categoryId: groceriesCategory.id,
            date: DateTime.utc(2026, 5, 15),
            createdAt: DateTime.utc(2026, 5, 15),
          ),
        );

        final report = await reportsRepository.getCashFlowReport(
          ReportsTimeframe.custom,
          customStart: DateTime(2026, 5, 1),
          customEnd: DateTime(2026, 5, 31),
        );

        // Total Income: $1,000 USD + $1,000 USD (from LKR) = $2,000 USD (200000)
        expect(report.totalIncome.currencyCode, 'USD');
        expect(report.totalIncome.minorUnits, 200000);

        // Total Expense: $55.00 USD (5500)
        expect(report.totalExpense.currencyCode, 'USD');
        expect(report.totalExpense.minorUnits, 5500);

        // Net Cash Flow: $2,000.00 - $55.00 = $1,945.00 USD (194500)
        expect(report.netCashFlow.currencyCode, 'USD');
        expect(report.netCashFlow.minorUnits, 194500);
      });

      test('consolidates category breakdown in primary reporting currency across diverse account currencies', () async {
        final eurAccount = Account(
          id: 'acc-eur-report',
          name: 'EUR Travel',
          type: AccountType.checking,
          currencyCode: 'EUR',
          initialBalance: const Money(100000, 'EUR'),
          currentBalance: const Money(100000, 'EUR'),
          isArchived: false,
          icon: 'euro',
          color: 0xFF3B82F6,
          createdAt: DateTime.utc(2026, 1, 1),
        );
        await accountRepository.createAccount(eurAccount);

        // Groceries expense in USD: $40.00 USD
        await transactionRepository.createTransaction(
          Transaction(
            id: 'tx-exp-usd',
            accountId: checkingAccount.id,
            type: TransactionType.expense,
            amount: const Money(4000, 'USD'),
            categoryId: groceriesCategory.id,
            date: DateTime.utc(2026, 5, 10),
            createdAt: DateTime.utc(2026, 5, 10),
          ),
        );

        // Groceries expense in EUR: €50.00 EUR (5000 cents).
        // Rate: EUR -> USD is 108695652, converts to $54.35 USD (5435 cents)
        await transactionRepository.createTransaction(
          Transaction(
            id: 'tx-exp-eur',
            accountId: eurAccount.id,
            type: TransactionType.expense,
            amount: const Money(5000, 'EUR'),
            categoryId: groceriesCategory.id,
            date: DateTime.utc(2026, 5, 12),
            createdAt: DateTime.utc(2026, 5, 12),
          ),
        );

        final report = await reportsRepository.getCategoryBreakdownReport(
          ReportsTimeframe.custom,
          customStart: DateTime(2026, 5, 1),
          customEnd: DateTime(2026, 5, 31),
        );

        expect(report.totalExpense.currencyCode, 'USD');
        // Total: 4000 + 5435 = 9435 cents ($94.35 USD)
        expect(report.totalExpense.minorUnits, 9435);
        expect(report.items.length, 1);
        expect(report.items.first.category.id, groceriesCategory.id);
        expect(report.items.first.amount.currencyCode, 'USD');
        expect(report.items.first.amount.minorUnits, 9435);
      });

      test('consolidates net worth trend converting multi-currency account balances', () async {
        // Checking: $1,000 USD (100000)
        // Savings: $2,000 USD (200000)
        // EUR Account: €1,000 EUR (100000 cents) -> at 1.08695652 converts to $1,086.96 USD (108696 cents)
        final eurAccount = Account(
          id: 'acc-eur-nw',
          name: 'EUR Savings',
          type: AccountType.savings,
          currencyCode: 'EUR',
          initialBalance: const Money(100000, 'EUR'),
          currentBalance: const Money(100000, 'EUR'),
          isArchived: false,
          icon: 'euro',
          color: 0xFF3B82F6,
          createdAt: DateTime.utc(2026, 1, 1),
        );
        await accountRepository.createAccount(eurAccount);

        final report = await reportsRepository.getNetWorthTrendReport(
          ReportsTimeframe.thisMonth,
        );

        expect(report.currentNetWorth.currencyCode, 'USD');
        // Total: 100000 + 200000 + 108696 = 408696 cents ($4,086.96 USD)
        expect(report.currentNetWorth.minorUnits, 408696);
      });
    });
  });
}
