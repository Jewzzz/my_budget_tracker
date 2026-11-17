import '../entities/budget.dart';
import '../entities/category_budget_overview.dart';

abstract class BudgetRepository {
  Future<void> setBudget(Budget budget);
  Future<void> deleteBudget(String id);
  Future<List<Budget>> getBudgets(int year, int month);
  Stream<List<Budget>> watchBudgets(int year, int month);
  Future<List<CategoryBudgetOverview>> getBudgetOverviews(int year, int month);
  Stream<List<CategoryBudgetOverview>> watchBudgetOverviews(int year, int month);
}
