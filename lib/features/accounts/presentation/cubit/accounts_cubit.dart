import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/value_objects/money.dart';
import '../../domain/entities/account.dart';
import '../../domain/repositories/account_repository.dart';
import 'accounts_state.dart';

class AccountsCubit extends Cubit<AccountsState> {
  final AccountRepository repository;
  StreamSubscription<List<Account>>? _accountsSubscription;

  AccountsCubit(this.repository) : super(const AccountsInitial());

  void loadAccounts({bool includeArchived = false}) {
    emit(const AccountsLoading());
    _accountsSubscription?.cancel();
    _accountsSubscription = repository
        .watchAccounts(includeArchived: includeArchived)
        .listen(
      (accounts) {
        final totalMinorUnits = accounts.fold<int>(
          0,
          (sum, acc) => sum + acc.currentBalance.minorUnits,
        );
        emit(
          AccountsLoaded(
            accounts: accounts,
            totalBalance: Money(totalMinorUnits),
            includeArchived: includeArchived,
          ),
        );
      },
      onError: (error) {
        emit(AccountsError(error.toString()));
      },
    );
  }

  Future<void> createAccount(Account account) async {
    try {
      await repository.createAccount(account);
      final current = state;
      final includeArchived = current is AccountsLoaded ? current.includeArchived : false;
      loadAccounts(includeArchived: includeArchived);
    } catch (e) {
      _emitError(e);
    }
  }

  Future<void> updateAccount(Account account) async {
    try {
      await repository.updateAccount(account);
      final current = state;
      final includeArchived = current is AccountsLoaded ? current.includeArchived : false;
      loadAccounts(includeArchived: includeArchived);
    } catch (e) {
      _emitError(e);
    }
  }

  Future<void> archiveAccount(String id, bool isArchived) async {
    try {
      await repository.archiveAccount(id, isArchived);
    } catch (e) {
      _emitError(e);
    }
  }

  Future<void> deleteAccount(String id) async {
    try {
      await repository.deleteAccount(id);
    } catch (e) {
      _emitError(e);
    }
  }

  void _emitError(Object error) {
    final message = error is DomainFailure ? error.message : error.toString();
    if (state is AccountsLoaded) {
      emit((state as AccountsLoaded).copyWith(errorMessage: message));
    } else {
      emit(AccountsError(message));
    }
  }

  @override
  Future<void> close() {
    _accountsSubscription?.cancel();
    return super.close();
  }
}
