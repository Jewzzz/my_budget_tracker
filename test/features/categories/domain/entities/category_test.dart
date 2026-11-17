import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_tracker/features/categories/domain/entities/category.dart';

void main() {
  group('Category Entity Unit Tests', () {
    test('creates Category instance and supports value equality', () {
      final category1 = Category(
        id: 'cat-groceries',
        name: 'Groceries',
        type: CategoryType.expense,
        icon: 'shopping_cart',
        color: 0xFF10B981,
        isDefault: true,
      );

      final category2 = Category(
        id: 'cat-groceries',
        name: 'Groceries',
        type: CategoryType.expense,
        icon: 'shopping_cart',
        color: 0xFF10B981,
        isDefault: true,
      );

      expect(category1, equals(category2));
      expect(category1.isExpense, isTrue);
      expect(category1.isIncome, isFalse);
    });

    test('CategoryType parser returns correct enum or falls back', () {
      expect(CategoryType.fromString('expense'), CategoryType.expense);
      expect(CategoryType.fromString('income'), CategoryType.income);
      expect(CategoryType.fromString('unknown'), CategoryType.expense);
    });
  });
}
