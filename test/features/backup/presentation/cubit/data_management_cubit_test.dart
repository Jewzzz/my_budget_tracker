import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_tracker/core/error/failures.dart';
import 'package:my_budget_tracker/features/backup/domain/repositories/backup_repository.dart';
import 'package:my_budget_tracker/features/backup/domain/services/share_service.dart';
import 'package:my_budget_tracker/features/backup/presentation/cubit/data_management_cubit.dart';
import 'package:my_budget_tracker/features/backup/presentation/cubit/data_management_state.dart';

class MockBackupRepository implements BackupRepository {
  String backupJson = '{"valid": true}';
  String csvContent = 'Date,Type\n2026-11-15,expense';
  bool restoreShouldFail = false;
  DomainFailure? failureToThrow;

  @override
  Future<String> exportBackupJson() async => backupJson;

  @override
  Future<String> exportTransactionsCsv() async => csvContent;

  @override
  Future<void> restoreFromJson(String json) async {
    if (restoreShouldFail) {
      throw failureToThrow ?? const InvalidChecksumFailure();
    }
  }

  @override
  Future<File> writeBackupToFile(String backupJson, {String? fileName}) async {
    return File('/tmp/test_backup.json');
  }

  @override
  Future<File> writeCsvToFile(String csvContent, {String? fileName}) async {
    return File('/tmp/test_transactions.csv');
  }
}

class MockShareService implements ShareService {
  String? sharedFilePath;
  String? sharedSubject;

  @override
  Future<void> shareFile(String filePath, {String? subject, String? text}) async {
    sharedFilePath = filePath;
    sharedSubject = subject;
  }
}

class MockFilePickerService implements FilePickerService {
  String? contentToReturn;

  @override
  Future<String?> pickJsonFileContent() async => contentToReturn;
}

void main() {
  late MockBackupRepository mockBackupRepository;
  late MockShareService mockShareService;
  late MockFilePickerService mockFilePickerService;
  late DataManagementCubit cubit;

  setUp(() {
    mockBackupRepository = MockBackupRepository();
    mockShareService = MockShareService();
    mockFilePickerService = MockFilePickerService();
    cubit = DataManagementCubit(
      backupRepository: mockBackupRepository,
      shareService: mockShareService,
      filePickerService: mockFilePickerService,
    );
  });

  tearDown(() {
    cubit.close();
  });

  group('DataManagementCubit', () {
    test('initial state is DataManagementStatus.initial', () {
      expect(cubit.state.status, DataManagementStatus.initial);
    });

    test('exportBackup writes file, triggers share sheet, and emits success', () async {
      await cubit.exportBackup();

      expect(mockShareService.sharedFilePath, '/tmp/test_backup.json');
      expect(mockShareService.sharedSubject, 'My Budget Tracker Backup');
      expect(cubit.state.status, DataManagementStatus.success);
      expect(cubit.state.message, contains('Backup exported successfully'));
      expect(cubit.state.exportedFilePath, '/tmp/test_backup.json');
    });

    test('exportTransactionsCsv writes file, triggers share sheet, and emits success', () async {
      await cubit.exportTransactionsCsv();

      expect(mockShareService.sharedFilePath, '/tmp/test_transactions.csv');
      expect(mockShareService.sharedSubject, 'Transactions CSV Export');
      expect(cubit.state.status, DataManagementStatus.success);
      expect(cubit.state.message, contains('Transactions exported successfully'));
    });

    test('restoreFromSelectedFile succeeds when file is picked and valid', () async {
      mockFilePickerService.contentToReturn = '{"schemaVersion": 1}';

      final success = await cubit.restoreFromSelectedFile();

      expect(success, isTrue);
      expect(cubit.state.status, DataManagementStatus.success);
      expect(cubit.state.message, contains('Data restored successfully'));
    });

    test('restoreFromSelectedFile does nothing if user cancels file picker', () async {
      mockFilePickerService.contentToReturn = null;

      final success = await cubit.restoreFromSelectedFile();

      expect(success, isFalse);
      expect(cubit.state.status, DataManagementStatus.initial);
    });

    test('restoreFromSelectedFile emits failure if repository throws failure', () async {
      mockFilePickerService.contentToReturn = '{"schemaVersion": 1}';
      mockBackupRepository.restoreShouldFail = true;
      mockBackupRepository.failureToThrow = const InvalidChecksumFailure('Checksum invalid');

      final success = await cubit.restoreFromSelectedFile();

      expect(success, isFalse);
      expect(cubit.state.status, DataManagementStatus.failure);
      expect(cubit.state.message, 'Checksum invalid');
    });
  });
}
