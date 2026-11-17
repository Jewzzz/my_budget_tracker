abstract class DomainFailure {
  final String message;
  const DomainFailure(this.message);

  @override
  String toString() => message;
}

class AccountHasTransactionsFailure extends DomainFailure {
  const AccountHasTransactionsFailure([String? message])
      : super(message ?? 'Cannot delete an account with existing transactions. Archive it instead.');
}

class AccountNotFoundFailure extends DomainFailure {
  const AccountNotFoundFailure([String? message])
      : super(message ?? 'Account was not found.');
}

class InvalidTransactionAmountFailure extends DomainFailure {
  const InvalidTransactionAmountFailure([String? message])
      : super(message ?? 'Transaction amount must be strictly greater than zero.');
}

class InsufficientFundsFailure extends DomainFailure {
  const InsufficientFundsFailure([String? message])
      : super(message ?? 'Selected account has insufficient funds for this action.');
}

class SameSourceAndDestinationAccountFailure extends DomainFailure {
  const SameSourceAndDestinationAccountFailure([String? message])
      : super(message ?? 'Source and destination accounts must be distinct.');
}

class MissingCategoryFailure extends DomainFailure {
  const MissingCategoryFailure([String? message])
      : super(message ?? 'A category is required for expense and income transactions.');
}

class CategoryHasTransactionsFailure extends DomainFailure {
  const CategoryHasTransactionsFailure([String? message])
      : super(message ?? 'Cannot delete category in use by existing transactions.');
}

class DatabaseFailure extends DomainFailure {
  const DatabaseFailure(super.message);
}
