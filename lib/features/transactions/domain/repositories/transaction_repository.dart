import '../entities/transaction.dart';

abstract class TransactionRepository {
  Future<void> createTransaction(Transaction transaction);
  Future<List<Transaction>> getTransactions({String? accountId, int? limit});
  Future<List<Transaction>> getRecentTransactions({int limit = 5});
  Stream<List<Transaction>> watchTransactions({String? accountId, int? limit});
  Stream<List<Transaction>> watchRecentTransactions({int limit = 5});
  Future<Transaction?> getTransactionById(String id);
}
