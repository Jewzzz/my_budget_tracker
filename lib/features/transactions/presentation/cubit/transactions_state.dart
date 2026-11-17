import 'package:equatable/equatable.dart';
import '../../../categories/domain/entities/category.dart';
import '../../domain/entities/transaction.dart';

sealed class TransactionsState extends Equatable {
  const TransactionsState();

  @override
  List<Object?> get props => [];
}

class TransactionsInitial extends TransactionsState {
  const TransactionsInitial();
}

class TransactionsLoading extends TransactionsState {
  const TransactionsLoading();
}

class TransactionsLoaded extends TransactionsState {
  final List<Transaction> allTransactions;
  final List<Transaction> recentTransactions;
  final List<Category> categories;
  final String? errorMessage;

  const TransactionsLoaded({
    this.allTransactions = const [],
    this.recentTransactions = const [],
    this.categories = const [],
    this.errorMessage,
  });

  TransactionsLoaded copyWith({
    List<Transaction>? allTransactions,
    List<Transaction>? recentTransactions,
    List<Category>? categories,
    String? errorMessage,
    bool clearError = false,
  }) {
    return TransactionsLoaded(
      allTransactions: allTransactions ?? this.allTransactions,
      recentTransactions: recentTransactions ?? this.recentTransactions,
      categories: categories ?? this.categories,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        allTransactions,
        recentTransactions,
        categories,
        errorMessage,
      ];
}

class TransactionsError extends TransactionsState {
  final String message;

  const TransactionsError(this.message);

  @override
  List<Object?> get props => [message];
}
