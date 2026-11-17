import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/value_objects/money.dart';
import '../../domain/entities/budget.dart';
import '../../domain/entities/category_budget_overview.dart';
import '../../domain/repositories/budget_repository.dart';
import 'budgets_state.dart';

class BudgetsCubit extends Cubit<BudgetsState> {
  final BudgetRepository budgetRepository;
  StreamSubscription<List<CategoryBudgetOverview>>? _subscription;

  int _currentYear = DateTime.now().year;
  int _currentMonth = DateTime.now().month;

  BudgetsCubit(this.budgetRepository) : super(const BudgetsInitial());

  void loadBudgets([int? year, int? month]) {
    _currentYear = year ?? _currentYear;
    _currentMonth = month ?? _currentMonth;

    emit(const BudgetsLoading());
    _subscription?.cancel();
    _subscription = budgetRepository
        .watchBudgetOverviews(_currentYear, _currentMonth)
        .listen(
      (overviews) {
        emit(
          BudgetsLoaded(
            year: _currentYear,
            month: _currentMonth,
            budgets: overviews,
          ),
        );
      },
      onError: (error) {
        emit(BudgetsError(error.toString()));
      },
    );
  }

  void nextMonth() {
    int year = _currentYear;
    int month = _currentMonth;
    if (state is BudgetsLoaded) {
      year = (state as BudgetsLoaded).year;
      month = (state as BudgetsLoaded).month;
    }

    if (month == 12) {
      year++;
      month = 1;
    } else {
      month++;
    }
    loadBudgets(year, month);
  }

  void previousMonth() {
    int year = _currentYear;
    int month = _currentMonth;
    if (state is BudgetsLoaded) {
      year = (state as BudgetsLoaded).year;
      month = (state as BudgetsLoaded).month;
    }

    if (month == 1) {
      year--;
      month = 12;
    } else {
      month--;
    }
    loadBudgets(year, month);
  }

  Future<void> setSpendingLimit({
    required String categoryId,
    required Money limitAmount,
    int? year,
    int? month,
  }) async {
    int y = year ?? _currentYear;
    int m = month ?? _currentMonth;
    if (year == null && month == null && state is BudgetsLoaded) {
      y = (state as BudgetsLoaded).year;
      m = (state as BudgetsLoaded).month;
    }
    final budget = Budget(
      id: const Uuid().v4(),
      categoryId: categoryId,
      year: y,
      month: m,
      limitAmount: limitAmount,
    );

    try {
      await budgetRepository.setBudget(budget);
    } catch (e) {
      if (state is BudgetsLoaded) {
        emit((state as BudgetsLoaded).copyWith(errorMessage: e.toString()));
      } else {
        emit(BudgetsError(e.toString()));
      }
    }
  }

  Future<void> deleteBudget(String id) async {
    try {
      await budgetRepository.deleteBudget(id);
    } catch (e) {
      if (state is BudgetsLoaded) {
        emit((state as BudgetsLoaded).copyWith(errorMessage: e.toString()));
      } else {
        emit(BudgetsError(e.toString()));
      }
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
