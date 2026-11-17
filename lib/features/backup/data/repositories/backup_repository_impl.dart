import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/error/failures.dart';
import '../../domain/repositories/backup_repository.dart';

class BackupRepositoryImpl implements BackupRepository {
  final AppDatabase database;
  final Future<Directory> Function()? documentsDirectoryProvider;

  BackupRepositoryImpl({
    required this.database,
    this.documentsDirectoryProvider,
  });

  Future<Directory> _getDocsDir() async {
    if (documentsDirectoryProvider != null) {
      return await documentsDirectoryProvider!();
    }
    return await getApplicationDocumentsDirectory();
  }

  @override
  Future<String> exportBackupJson() async {
    final accounts = (await database.select(database.accounts).get()).map((r) => r.toJson()).toList();
    final categories = (await database.select(database.categories).get()).map((r) => r.toJson()).toList();
    final budgets = (await database.select(database.budgets).get()).map((r) => r.toJson()).toList();
    final savingsGoals = (await database.select(database.savingsGoals).get()).map((r) => r.toJson()).toList();
    final transactions = (await database.select(database.transactions).get()).map((r) => r.toJson()).toList();
    final goalContributions =
        (await database.select(database.goalContributions).get()).map((r) => r.toJson()).toList();

    final data = {
      'accounts': accounts,
      'categories': categories,
      'budgets': budgets,
      'savingsGoals': savingsGoals,
      'transactions': transactions,
      'goalContributions': goalContributions,
    };

    final checksum = sha256.convert(utf8.encode(jsonEncode(data))).toString();

    final snapshot = {
      'schemaVersion': 1,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'checksum': checksum,
      'data': data,
    };

    return jsonEncode(snapshot);
  }

  @override
  Future<void> restoreFromJson(String backupJson) async {
    Map<String, dynamic> map;
    try {
      map = jsonDecode(backupJson) as Map<String, dynamic>;
    } catch (e) {
      throw CorruptBackupFailure('Malformed JSON string: $e');
    }

    if (!map.containsKey('schemaVersion') ||
        !map.containsKey('checksum') ||
        !map.containsKey('data') ||
        map['data'] is! Map<String, dynamic>) {
      throw const CorruptBackupFailure('Missing required backup metadata.');
    }

    final schemaVersion = map['schemaVersion'];
    if (schemaVersion is! int || schemaVersion != 1) {
      throw IncompatibleSchemaFailure('Unsupported schema version: $schemaVersion');
    }

    final expectedChecksum = map['checksum'] as String;
    final data = map['data'] as Map<String, dynamic>;
    final calculatedChecksum = sha256.convert(utf8.encode(jsonEncode(data))).toString();

    if (calculatedChecksum != expectedChecksum) {
      throw const InvalidChecksumFailure();
    }

    try {
      await database.transaction(() async {
        // Delete existing data in reverse foreign-key order
        await database.delete(database.goalContributions).go();
        await database.delete(database.transactions).go();
        await database.delete(database.savingsGoals).go();
        await database.delete(database.budgets).go();
        await database.delete(database.categories).go();
        await database.delete(database.accounts).go();

        // Deserialize and insert in dependency order
        final categoriesList = (data['categories'] as List? ?? [])
            .map((e) => CategoryRow.fromJson(e as Map<String, dynamic>))
            .toList();
        final accountsList =
            (data['accounts'] as List? ?? []).map((e) => AccountRow.fromJson(e as Map<String, dynamic>)).toList();
        final budgetsList =
            (data['budgets'] as List? ?? []).map((e) => BudgetRow.fromJson(e as Map<String, dynamic>)).toList();
        final savingsGoalsList = (data['savingsGoals'] as List? ?? [])
            .map((e) => SavingsGoalRow.fromJson(e as Map<String, dynamic>))
            .toList();
        final transactionsList = (data['transactions'] as List? ?? [])
            .map((e) => TransactionRow.fromJson(e as Map<String, dynamic>))
            .toList();
        final goalContributionsList = (data['goalContributions'] as List? ?? [])
            .map((e) => GoalContributionRow.fromJson(e as Map<String, dynamic>))
            .toList();

        await database.batch((b) {
          b.insertAll(database.categories, categoriesList);
          b.insertAll(database.accounts, accountsList);
          b.insertAll(database.budgets, budgetsList);
          b.insertAll(database.savingsGoals, savingsGoalsList);
          b.insertAll(database.transactions, transactionsList);
          b.insertAll(database.goalContributions, goalContributionsList);
        });
      });
    } catch (e) {
      if (e is DomainFailure) rethrow;
      throw RestoreDataFailure('Database restore failed and was rolled back: $e');
    }
  }

  @override
  Future<String> exportTransactionsCsv() async {
    final allAccounts = await database.select(database.accounts).get();
    final accountNames = {for (final a in allAccounts) a.id: a.name};

    final allCategories = await database.select(database.categories).get();
    final categoryNames = {for (final c in allCategories) c.id: c.name};

    final txQuery = database.select(database.transactions)
      ..orderBy([(t) => OrderingTerm(expression: t.transactionDate, mode: OrderingMode.desc)]);
    final transactions = await txQuery.get();

    final buffer = StringBuffer();
    buffer.writeln('Date,Type,Account,Category,Amount,Currency,Note');

    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

    for (final tx in transactions) {
      final dateStr = dateFormat.format(DateTime.fromMillisecondsSinceEpoch(tx.transactionDate));
      final type = tx.transactionType;
      final account = _escapeCsvField(accountNames[tx.accountId] ?? tx.accountId);
      final category = _escapeCsvField(tx.categoryId != null ? (categoryNames[tx.categoryId] ?? '') : '');
      final amount = (tx.amountMinorUnits / 100.0).toStringAsFixed(2);
      const currency = 'USD';
      final note = _escapeCsvField(tx.note ?? '');

      buffer.writeln('$dateStr,$type,$account,$category,$amount,$currency,$note');
    }

    return buffer.toString().trimRight();
  }

  String _escapeCsvField(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n') || field.contains('\r')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  @override
  Future<File> writeBackupToFile(String backupJson, {String? fileName}) async {
    final dir = await _getDocsDir();
    final timestamp = DateTime.now().toUtc().toIso8601String().replaceAll(':', '-');
    final name = fileName ?? 'my_budget_backup_$timestamp.json';
    final file = File(p.join(dir.path, name));
    return await file.writeAsString(backupJson);
  }

  @override
  Future<File> writeCsvToFile(String csvContent, {String? fileName}) async {
    final dir = await _getDocsDir();
    final timestamp = DateTime.now().toUtc().toIso8601String().replaceAll(':', '-');
    final name = fileName ?? 'transactions_$timestamp.csv';
    final file = File(p.join(dir.path, name));
    return await file.writeAsString(csvContent);
  }
}
