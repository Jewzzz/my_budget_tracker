import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_budget_tracker/core/error/failures.dart';
import 'package:my_budget_tracker/core/value_objects/money.dart';
import 'package:my_budget_tracker/features/accounts/domain/entities/account.dart';
import 'package:my_budget_tracker/features/accounts/domain/repositories/account_repository.dart';
import 'package:my_budget_tracker/features/accounts/presentation/cubit/accounts_cubit.dart';
import 'package:my_budget_tracker/features/accounts/presentation/cubit/accounts_state.dart';

class MockAccountRepository extends Mock implements AccountRepository {}

void main() {
  group('AccountsCubit Unit Tests', () {
    late AccountRepository repository;
    late AccountsCubit cubit;

    final testAccount1 = Account(
      id: 'acc-1',
      name: 'Checking',
      type: AccountType.checking,
      initialBalance: const Money(30000),
      currentBalance: const Money(30000),
      isArchived: false,
      icon: 'account_balance',
      color: 0xFF1E3A8A,
      createdAt: DateTime.utc(2026, 1, 1),
    );

    final testAccount2 = Account(
      id: 'acc-2',
      name: 'Savings',
      type: AccountType.savings,
      initialBalance: const Money(70000),
      currentBalance: const Money(70000),
      isArchived: false,
      icon: 'savings',
      color: 0xFF10B981,
      createdAt: DateTime.utc(2026, 1, 1),
    );

    setUp(() {
      repository = MockAccountRepository();
      cubit = AccountsCubit(repository);
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state is AccountsInitial', () {
      expect(cubit.state, const AccountsInitial());
    });

    blocTest<AccountsCubit, AccountsState>(
      'emits [AccountsLoading, AccountsLoaded] with calculated totalBalance on loadAccounts',
      build: () {
        when(() => repository.watchAccounts(includeArchived: false))
            .thenAnswer((_) => Stream.value([testAccount1, testAccount2]));
        return cubit;
      },
      act: (cubit) => cubit.loadAccounts(),
      expect: () => [
        const AccountsLoading(),
        AccountsLoaded(
          accounts: [testAccount1, testAccount2],
          totalBalance: const Money(100000), // $1000.00
          includeArchived: false,
        ),
      ],
    );

    blocTest<AccountsCubit, AccountsState>(
      'createAccount calls repository.createAccount and reloads accounts',
      build: () {
        when(() => repository.createAccount(testAccount1))
            .thenAnswer((_) async {});
        when(() => repository.watchAccounts(includeArchived: false))
            .thenAnswer((_) => Stream.value([testAccount1]));
        return cubit;
      },
      act: (cubit) => cubit.createAccount(testAccount1),
      verify: (_) {
        verify(() => repository.createAccount(testAccount1)).called(1);
      },
    );

    blocTest<AccountsCubit, AccountsState>(
      'deleteAccount emits AccountsError when repository throws AccountHasTransactionsFailure',
      build: () {
        when(() => repository.deleteAccount('acc-1'))
            .thenThrow(const AccountHasTransactionsFailure());
        return cubit;
      },
      seed: () => AccountsLoaded(
        accounts: [testAccount1],
        totalBalance: const Money(30000),
        includeArchived: false,
      ),
      act: (cubit) => cubit.deleteAccount('acc-1'),
      expect: () => [
        AccountsLoaded(
          accounts: [testAccount1],
          totalBalance: const Money(30000),
          includeArchived: false,
          errorMessage: 'Cannot delete an account with existing transactions. Archive it instead.',
        ),
      ],
    );
  });
}
