import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_tracker/core/database/app_database.dart';

void main() {
  group('AppDatabase Initialization', () {
    late AppDatabase database;

    setUp(() {
      database = AppDatabase.inMemory();
    });

    tearDown(() async {
      await database.close();
    });

    test('initializes in-memory database with schema version 2', () async {
      expect(database.schemaVersion, 2);
    });

    test('seeds default exchange rates on database creation', () async {
      final rates = await database.select(database.exchangeRates).get();
      expect(rates.isNotEmpty, isTrue);
      expect(rates.any((r) => r.baseCurrency == 'USD' && r.targetCurrency == 'LKR'), isTrue);
    });

    test('executes simple query to verify SQLite connection', () async {
      final result = await database.customSelect('SELECT 1 + 1 AS sum').getSingle();
      expect(result.read<int>('sum'), 2);
    });
  });
}

