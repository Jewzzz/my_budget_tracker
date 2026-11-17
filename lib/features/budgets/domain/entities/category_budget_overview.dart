import 'package:equatable/equatable.dart';
import '../../../../core/value_objects/money.dart';
import '../../../categories/domain/entities/category.dart';
import 'budget.dart';

class CategoryBudgetOverview extends Equatable {
  final Budget budget;
  final Category category;
  final Money spentAmount;

  const CategoryBudgetOverview({
    required this.budget,
    required this.category,
    required this.spentAmount,
  });

  Money get remainingAmount => budget.limitAmount - spentAmount;

  bool get isOverBudget => spentAmount > budget.limitAmount;

  double get percentageSpent {
    if (budget.limitAmount.minorUnits <= 0) return 0.0;
    return spentAmount.minorUnits / budget.limitAmount.minorUnits;
  }

  @override
  List<Object?> get props => [budget, category, spentAmount];
}
