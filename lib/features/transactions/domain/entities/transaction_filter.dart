import 'package:equatable/equatable.dart';
import '../../../categories/domain/entities/category.dart';
import 'transaction.dart';

class TransactionFilter extends Equatable {
  final String? searchQuery;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? accountId;
  final String? categoryId;
  final TransactionType? type;

  const TransactionFilter({
    this.searchQuery,
    this.startDate,
    this.endDate,
    this.accountId,
    this.categoryId,
    this.type,
  });

  bool get isEmpty =>
      (searchQuery == null || searchQuery!.trim().isEmpty) &&
      startDate == null &&
      endDate == null &&
      accountId == null &&
      categoryId == null &&
      type == null;

  bool matches(Transaction txn, [List<Category> categories = const []]) {
    // 1. Search query: checks note and category name
    if (searchQuery != null && searchQuery!.trim().isNotEmpty) {
      final query = searchQuery!.trim().toLowerCase();
      final noteMatch = txn.note != null && txn.note!.toLowerCase().contains(query);
      bool categoryMatch = false;
      if (txn.categoryId != null) {
        final cat = categories.where((c) => c.id == txn.categoryId).firstOrNull;
        if (cat != null && cat.name.toLowerCase().contains(query)) {
          categoryMatch = true;
        }
      }
      if (!noteMatch && !categoryMatch) {
        return false;
      }
    }

    // 2. Transaction Type
    if (type != null && txn.type != type) {
      return false;
    }

    // 3. Account ID (source or destination)
    if (accountId != null &&
        txn.accountId != accountId &&
        txn.destinationAccountId != accountId) {
      return false;
    }

    // 4. Category ID
    if (categoryId != null && txn.categoryId != categoryId) {
      return false;
    }

    // 5. Date Range
    if (startDate != null && txn.date.isBefore(startDate!)) {
      return false;
    }
    if (endDate != null && txn.date.isAfter(endDate!)) {
      return false;
    }

    return true;
  }

  TransactionFilter copyWith({
    String? searchQuery,
    bool clearSearchQuery = false,
    DateTime? startDate,
    bool clearStartDate = false,
    DateTime? endDate,
    bool clearEndDate = false,
    String? accountId,
    bool clearAccountId = false,
    String? categoryId,
    bool clearCategoryId = false,
    TransactionType? type,
    bool clearType = false,
  }) {
    return TransactionFilter(
      searchQuery: clearSearchQuery ? null : (searchQuery ?? this.searchQuery),
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      accountId: clearAccountId ? null : (accountId ?? this.accountId),
      categoryId: clearCategoryId ? null : (categoryId ?? this.categoryId),
      type: clearType ? null : (type ?? this.type),
    );
  }

  @override
  List<Object?> get props => [
        searchQuery,
        startDate,
        endDate,
        accountId,
        categoryId,
        type,
      ];
}
