import 'package:equatable/equatable.dart';
import '../../../../core/value_objects/money.dart';
import '../../domain/entities/account.dart';

sealed class AccountsState extends Equatable {
  const AccountsState();

  @override
  List<Object?> get props => [];
}

class AccountsInitial extends AccountsState {
  const AccountsInitial();
}

class AccountsLoading extends AccountsState {
  const AccountsLoading();
}

class AccountsLoaded extends AccountsState {
  final List<Account> accounts;
  final Money totalBalance;
  final bool includeArchived;
  final String? errorMessage;

  const AccountsLoaded({
    required this.accounts,
    required this.totalBalance,
    this.includeArchived = false,
    this.errorMessage,
  });

  AccountsLoaded copyWith({
    List<Account>? accounts,
    Money? totalBalance,
    bool? includeArchived,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AccountsLoaded(
      accounts: accounts ?? this.accounts,
      totalBalance: totalBalance ?? this.totalBalance,
      includeArchived: includeArchived ?? this.includeArchived,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [accounts, totalBalance, includeArchived, errorMessage];
}

class AccountsError extends AccountsState {
  final String message;

  const AccountsError(this.message);

  @override
  List<Object?> get props => [message];
}
