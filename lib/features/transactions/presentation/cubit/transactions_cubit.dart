import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/failures.dart';
import '../../../categories/domain/entities/category.dart';
import '../../../categories/domain/repositories/category_repository.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';
import 'transactions_state.dart';

class TransactionsCubit extends Cubit<TransactionsState> {
  final TransactionRepository transactionRepository;
  final CategoryRepository categoryRepository;

  StreamSubscription<List<Transaction>>? _allTransactionsSub;

  List<Category> _cachedCategories = [];
  List<Transaction> _currentAllTransactions = [];
  List<Transaction> _currentRecentTransactions = [];

  TransactionsCubit({
    required this.transactionRepository,
    required this.categoryRepository,
  }) : super(const TransactionsInitial());

  Future<void> loadTransactions() async {
    emit(const TransactionsLoading());
    try {
      _cachedCategories = await categoryRepository.getCategories();
    } catch (_) {
      // Ignore initial category load errors or let empty list fallback
    }

    _allTransactionsSub?.cancel();

    _allTransactionsSub = transactionRepository.watchTransactions().listen(
      (transactions) {
        _currentAllTransactions = transactions;
        _currentRecentTransactions = transactions.take(5).toList();
        _emitLoaded();
      },
      onError: (error) {
        emit(TransactionsError(error.toString()));
      },
    );
  }

  void _emitLoaded() {
    emit(
      TransactionsLoaded(
        allTransactions: _currentAllTransactions,
        recentTransactions: _currentRecentTransactions,
        categories: _cachedCategories,
      ),
    );
  }

  Future<void> createTransaction(Transaction transaction) async {
    try {
      await transactionRepository.createTransaction(transaction);
    } catch (e) {
      final message = e is DomainFailure ? e.message : e.toString();
      if (state is TransactionsLoaded) {
        emit((state as TransactionsLoaded).copyWith(errorMessage: message));
      } else {
        emit(TransactionsError(message));
      }
    }
  }

  @override
  Future<void> close() {
    _allTransactionsSub?.cancel();
    return super.close();
  }
}
