import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_tracker/core/database/app_database.dart';
import 'package:my_budget_tracker/core/error/failures.dart';
import 'package:my_budget_tracker/core/value_objects/money.dart';
import 'package:my_budget_tracker/features/accounts/data/repositories/account_repository_impl.dart';
import 'package:my_budget_tracker/features/accounts/domain/entities/account.dart';
import 'package:my_budget_tracker/features/categories/data/repositories/category_repository_impl.dart';
import 'package:my_budget_tracker/features/categories/domain/entities/category.dart';
import 'package:my_budget_tracker/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:my_budget_tracker/features/transactions/domain/entities/transaction.dart';

void main() {
  group('CategoryRepositoryImpl Integration Tests', () {
    late AppDatabase database;
    late CategoryRepositoryImpl categoryRepository;
    late AccountRepositoryImpl accountRepository;
    late TransactionRepositoryImpl transactionRepository;

    final testCustomCategory = Category(
      id: 'cat-books',
      name: 'Books & Learning',
      type: CategoryType.expense,
      icon: 'menu_book',
      color: 0xFF8B5CF6,
      isDefault: false,
    );

    setUp(() async {
      database = AppDatabase.inMemory();
      await database.seedDefaultCategoriesIfEmpty();
      categoryRepository = CategoryRepositoryImpl(database);
      accountRepository = AccountRepositoryImpl(database);
      transactionRepository = TransactionRepositoryImpl(database);
    });

    tearDown(() async {
      await database.close();
    });

    test('creates custom category and retrieves it', () async {
      await categoryRepository.createCategory(testCustomCategory);

      final retrieved = await categoryRepository.getCategoryById(testCustomCategory.id);
      expect(retrieved, isNotNull);
      expect(retrieved!.name, 'Books & Learning');
      expect(retrieved.isDefault, isFalse);
      expect(retrieved.icon, 'menu_book');
    });

    test('updates custom category name, icon, and color', () async {
      await categoryRepository.createCategory(testCustomCategory);

      final updated = testCustomCategory.copyWith(
        name: 'Books & Courses',
        icon: 'school',
        color: 0xFF3B82F6,
      );

      await categoryRepository.updateCategory(updated);

      final retrieved = await categoryRepository.getCategoryById(testCustomCategory.id);
      expect(retrieved!.name, 'Books & Courses');
      expect(retrieved.icon, 'school');
      expect(retrieved.color, 0xFF3B82F6);
    });

    test('deletes custom category when no transactions reference it', () async {
      await categoryRepository.createCategory(testCustomCategory);

      await categoryRepository.deleteCategory(testCustomCategory.id);

      final retrieved = await categoryRepository.getCategoryById(testCustomCategory.id);
      expect(retrieved, isNull);
    });

    test('throws DefaultCategoryCannotBeDeletedFailure when attempting to delete default category', () async {
      final defaultCategories = await categoryRepository.getCategories();
      expect(defaultCategories, isNotEmpty);
      final defaultCat = defaultCategories.firstWhere((c) => c.isDefault);

      expect(
        () => categoryRepository.deleteCategory(defaultCat.id),
        throwsA(isA<DefaultCategoryCannotBeDeletedFailure>()),
      );
    });

    test('throws CategoryHasTransactionsFailure when attempting to delete category in use by transactions', () async {
      await categoryRepository.createCategory(testCustomCategory);

      final account = Account(
        id: 'acc-1',
        name: 'Checking',
        type: AccountType.checking,
        initialBalance: const Money(50000),
        currentBalance: const Money(50000),
        icon: 'account_balance',
        color: 0xFF1E3A8A,
        createdAt: DateTime.utc(2026, 1, 1),
      );
      await accountRepository.createAccount(account);

      final txn = Transaction(
        id: 'txn-1',
        accountId: account.id,
        type: TransactionType.expense,
        amount: const Money(1500),
        categoryId: testCustomCategory.id,
        date: DateTime.utc(2026, 5, 1),
        createdAt: DateTime.utc(2026, 5, 1),
      );
      await transactionRepository.createTransaction(txn);

      expect(
        () => categoryRepository.deleteCategory(testCustomCategory.id),
        throwsA(isA<CategoryHasTransactionsFailure>()),
      );

      // Verify category was not deleted
      final retrieved = await categoryRepository.getCategoryById(testCustomCategory.id);
      expect(retrieved, isNotNull);
    });
  });
}
