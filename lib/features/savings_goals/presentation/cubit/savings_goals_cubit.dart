import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/value_objects/money.dart';
import '../../domain/entities/savings_goal.dart';
import '../../domain/repositories/savings_goal_repository.dart';
import 'savings_goals_state.dart';

class SavingsGoalsCubit extends Cubit<SavingsGoalsState> {
  final SavingsGoalRepository repository;
  StreamSubscription<List<SavingsGoal>>? _subscription;

  SavingsGoalsCubit(this.repository) : super(const SavingsGoalsInitial());

  void loadGoals() {
    emit(const SavingsGoalsLoading());
    _subscription?.cancel();
    _subscription = repository.watchGoals().listen(
      (goals) {
        emit(SavingsGoalsLoaded(goals: goals));
      },
      onError: (error) {
        emit(SavingsGoalsError(error.toString()));
      },
    );
  }

  Future<void> createGoal(SavingsGoal goal) async {
    try {
      await repository.createGoal(goal);
    } catch (e) {
      final msg = e is DomainFailure ? e.message : e.toString();
      if (state is SavingsGoalsLoaded) {
        emit((state as SavingsGoalsLoaded).copyWith(errorMessage: msg));
      } else {
        emit(SavingsGoalsError(msg));
      }
    }
  }

  Future<void> updateGoal(SavingsGoal goal) async {
    try {
      await repository.updateGoal(goal);
    } catch (e) {
      final msg = e is DomainFailure ? e.message : e.toString();
      if (state is SavingsGoalsLoaded) {
        emit((state as SavingsGoalsLoaded).copyWith(errorMessage: msg));
      } else {
        emit(SavingsGoalsError(msg));
      }
    }
  }

  Future<void> deleteGoal(String id) async {
    try {
      await repository.deleteGoal(id);
    } catch (e) {
      final msg = e is DomainFailure ? e.message : e.toString();
      if (state is SavingsGoalsLoaded) {
        emit((state as SavingsGoalsLoaded).copyWith(errorMessage: msg));
      } else {
        emit(SavingsGoalsError(msg));
      }
    }
  }

  Future<void> markCompleted(String id, bool completed) async {
    try {
      await repository.markCompleted(id, completed);
    } catch (e) {
      final msg = e is DomainFailure ? e.message : e.toString();
      if (state is SavingsGoalsLoaded) {
        emit((state as SavingsGoalsLoaded).copyWith(errorMessage: msg));
      } else {
        emit(SavingsGoalsError(msg));
      }
    }
  }

  Future<void> deposit({
    required String goalId,
    required String accountId,
    required Money amount,
    DateTime? date,
    String? note,
  }) async {
    try {
      await repository.deposit(
        goalId: goalId,
        accountId: accountId,
        amount: amount,
        date: date,
        note: note,
      );
    } catch (e) {
      final msg = e is DomainFailure ? e.message : e.toString();
      if (state is SavingsGoalsLoaded) {
        emit((state as SavingsGoalsLoaded).copyWith(errorMessage: msg));
      } else {
        emit(SavingsGoalsError(msg));
      }
    }
  }

  Future<void> withdraw({
    required String goalId,
    required String accountId,
    required Money amount,
    DateTime? date,
    String? note,
  }) async {
    try {
      await repository.withdraw(
        goalId: goalId,
        accountId: accountId,
        amount: amount,
        date: date,
        note: note,
      );
    } catch (e) {
      final msg = e is DomainFailure ? e.message : e.toString();
      if (state is SavingsGoalsLoaded) {
        emit((state as SavingsGoalsLoaded).copyWith(errorMessage: msg));
      } else {
        emit(SavingsGoalsError(msg));
      }
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
