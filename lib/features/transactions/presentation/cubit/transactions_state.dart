import 'package:equatable/equatable.dart';
import '../../../categories/domain/entities/category.dart';
import '../../domain/entities/day_grouped_transactions.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/transaction_filter.dart';

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
  final TransactionFilter filter;
  final String? errorMessage;

  const TransactionsLoaded({
    this.allTransactions = const [],
    this.recentTransactions = const [],
    this.categories = const [],
    this.filter = const TransactionFilter(),
    this.errorMessage,
  });

  List<Transaction> get filteredTransactions {
    if (filter.isEmpty) return allTransactions;
    return allTransactions.where((t) => filter.matches(t, categories)).toList();
  }

  List<DayGroupedTransactions> get groupedTransactions {
    return DayGroupedTransactions.group(filteredTransactions);
  }

  TransactionsLoaded copyWith({
    List<Transaction>? allTransactions,
    List<Transaction>? recentTransactions,
    List<Category>? categories,
    TransactionFilter? filter,
    String? errorMessage,
    bool clearError = false,
  }) {
    return TransactionsLoaded(
      allTransactions: allTransactions ?? this.allTransactions,
      recentTransactions: recentTransactions ?? this.recentTransactions,
      categories: categories ?? this.categories,
      filter: filter ?? this.filter,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        allTransactions,
        recentTransactions,
        categories,
        filter,
        errorMessage,
      ];
}

class TransactionsError extends TransactionsState {
  final String message;

  const TransactionsError(this.message);

  @override
  List<Object?> get props => [message];
}
