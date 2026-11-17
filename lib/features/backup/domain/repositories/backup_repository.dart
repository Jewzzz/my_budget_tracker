import 'dart:io';

abstract class BackupRepository {
  /// Packages all database tables into a structured JSON snapshot with metadata:
  /// schemaVersion, exportTimestamp, and SHA-256 checksum.
  Future<String> exportBackupJson();

  /// Validates file integrity, checks schema compatibility, and executes the entire
  /// restore inside an atomic SQLite transaction. Rolls back on error.
  Future<void> restoreFromJson(String backupJson);

  /// Formats all transactions (Date, Type, Account, Category, Amount in decimal, Currency, Note)
  /// into a standardized RFC 4180 CSV file.
  Future<String> exportTransactionsCsv();

  /// Writes backup JSON snapshot to a local file in the app documents directory.
  Future<File> writeBackupToFile(String backupJson, {String? fileName});

  /// Writes CSV string to a local file in the app documents directory.
  Future<File> writeCsvToFile(String csvContent, {String? fileName});
}
