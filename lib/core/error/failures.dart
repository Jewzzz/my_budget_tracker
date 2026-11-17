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

class DatabaseFailure extends DomainFailure {
  const DatabaseFailure(super.message);
}
