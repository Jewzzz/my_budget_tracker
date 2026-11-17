import '../entities/account.dart';

abstract class AccountRepository {
  Stream<List<Account>> watchAccounts({bool includeArchived = false});
  Future<List<Account>> getAccounts({bool includeArchived = false});
  Future<Account?> getAccountById(String id);
  Future<void> createAccount(Account account);
  Future<void> updateAccount(Account account);
  Future<void> archiveAccount(String id, bool isArchived);
  Future<void> deleteAccount(String id);
}
