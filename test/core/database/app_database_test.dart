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
      final settings = await database.select(database.appSettings).get();
      expect(settings, isEmpty);
    });

    test('executes simple query to verify SQLite connection', () async {
      final result = await database.customSelect('SELECT 1 + 1 AS sum').getSingle();
      expect(result.read<int>('sum'), 2);
    });
  });
}

