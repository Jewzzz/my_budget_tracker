import 'package:equatable/equatable.dart';
import '../../../../core/value_objects/money.dart';
import '../../domain/entities/category_budget_overview.dart';

sealed class BudgetsState extends Equatable {
  const BudgetsState();

  @override
  List<Object?> get props => [];
}

class BudgetsInitial extends BudgetsState {
  const BudgetsInitial();
}

class BudgetsLoading extends BudgetsState {
  const BudgetsLoading();
}

class BudgetsLoaded extends BudgetsState {
  final int year;
  final int month;
  final List<CategoryBudgetOverview> budgets;
  final String? errorMessage;

  const BudgetsLoaded({
    required this.year,
    required this.month,
    required this.budgets,
    this.errorMessage,
  });

  Money get totalBudgeted {
    int total = 0;
    for (final b in budgets) {
      total += b.budget.limitAmount.minorUnits;
    }
    return Money(total);
  }

  Money get totalSpent {
    int total = 0;
    for (final b in budgets) {
      total += b.spentAmount.minorUnits;
    }
    return Money(total);
  }

  Money get netRemaining => totalBudgeted - totalSpent;

  bool get hasOverBudget => budgets.any((b) => b.isOverBudget);

  int get overBudgetCount => budgets.where((b) => b.isOverBudget).length;

  BudgetsLoaded copyWith({
    int? year,
    int? month,
    List<CategoryBudgetOverview>? budgets,
    String? errorMessage,
    bool clearError = false,
  }) {
    return BudgetsLoaded(
      year: year ?? this.year,
      month: month ?? this.month,
      budgets: budgets ?? this.budgets,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [year, month, budgets, errorMessage];
}

class BudgetsError extends BudgetsState {
  final String message;

  const BudgetsError(this.message);

  @override
  List<Object?> get props => [message];
}
