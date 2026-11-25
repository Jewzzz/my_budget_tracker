import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/value_objects/money.dart';

enum TransactionType {
  expense,
  income,
  transfer;

  String get displayName {
    switch (this) {
      case TransactionType.expense:
        return 'Expense';
      case TransactionType.income:
        return 'Income';
      case TransactionType.transfer:
        return 'Transfer';
    }
  }

  static TransactionType fromString(String value) {
    return TransactionType.values.firstWhere(
      (type) => type.name.toLowerCase() == value.toLowerCase(),
      orElse: () => TransactionType.expense,
    );
  }
}

class Transaction extends Equatable {
  final String id;
  final String accountId;
  final TransactionType type;
  final Money amount; // Settlement amount in account's native currency
  final Money? originalAmount; // Optional original amount in foreign currency
  final int? exchangeRateScaled; // Optional exchange rate multiplied by 10^8
  final String? categoryId;
  final String? destinationAccountId;
  final DateTime date;
  final String? note;
  final DateTime createdAt;

  Transaction({
    required this.id,
    required this.accountId,
    required this.type,
    required this.amount,
    this.originalAmount,
    this.exchangeRateScaled,
    this.categoryId,
    this.destinationAccountId,
    required this.date,
    this.note,
    required this.createdAt,
  }) {
    if (amount.minorUnits <= 0) {
      throw const InvalidTransactionAmountFailure();
    }
    if ((type == TransactionType.expense || type == TransactionType.income) &&
        (categoryId == null || categoryId!.trim().isEmpty)) {
      throw const MissingCategoryFailure();
    }
    if (type == TransactionType.transfer) {
      if (destinationAccountId == null ||
          destinationAccountId!.trim().isEmpty ||
          destinationAccountId == accountId) {
        throw const SameSourceAndDestinationAccountFailure();
      }
    }
  }

  String get currencyCode => amount.currencyCode;
  bool get isExpense => type == TransactionType.expense;
  bool get isIncome => type == TransactionType.income;
  bool get isTransfer => type == TransactionType.transfer;

  Transaction copyWith({
    String? id,
    String? accountId,
    TransactionType? type,
    Money? amount,
    Money? originalAmount,
    int? exchangeRateScaled,
    String? categoryId,
    String? destinationAccountId,
    DateTime? date,
    String? note,
    DateTime? createdAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      originalAmount: originalAmount ?? this.originalAmount,
      exchangeRateScaled: exchangeRateScaled ?? this.exchangeRateScaled,
      categoryId: categoryId ?? this.categoryId,
      destinationAccountId: destinationAccountId ?? this.destinationAccountId,
      date: date ?? this.date,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        accountId,
        type,
        amount,
        originalAmount,
        exchangeRateScaled,
        categoryId,
        destinationAccountId,
        date,
        note,
        createdAt,
      ];
}
