import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/backup_repository.dart';
import '../../domain/services/share_service.dart';
import 'data_management_state.dart';

class DataManagementCubit extends Cubit<DataManagementState> {
  final BackupRepository backupRepository;
  final ShareService shareService;
  final FilePickerService filePickerService;

  DataManagementCubit({
    required this.backupRepository,
    required this.shareService,
    required this.filePickerService,
  }) : super(const DataManagementState());

  Future<void> exportBackup({bool share = true}) async {
    emit(state.copyWith(status: DataManagementStatus.loading));
    try {
      final jsonSnapshot = await backupRepository.exportBackupJson();
      final file = await backupRepository.writeBackupToFile(jsonSnapshot);

      if (share) {
        await shareService.shareFile(
          file.path,
          subject: 'My Budget Tracker Backup',
          text: 'My Budget Tracker full database backup snapshot.',
        );
      }

      emit(state.copyWith(
        status: DataManagementStatus.success,
        message: 'Backup exported successfully to ${file.path}',
        exportedFilePath: file.path,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: DataManagementStatus.failure,
        message: 'Export failed: $e',
      ));
    }
  }

  Future<void> exportTransactionsCsv({bool share = true}) async {
    emit(state.copyWith(status: DataManagementStatus.loading));
    try {
      final csv = await backupRepository.exportTransactionsCsv();
      final file = await backupRepository.writeCsvToFile(csv);

      if (share) {
        await shareService.shareFile(
          file.path,
          subject: 'Transactions CSV Export',
          text: 'Transactions exported from My Budget Tracker.',
        );
      }

      emit(state.copyWith(
        status: DataManagementStatus.success,
        message: 'Transactions exported successfully to ${file.path}',
        exportedFilePath: file.path,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: DataManagementStatus.failure,
        message: 'CSV export failed: $e',
      ));
    }
  }

  Future<bool> restoreFromSelectedFile({String? explicitContent}) async {
    String? content = explicitContent;
    if (content == null) {
      content = await filePickerService.pickJsonFileContent();
      if (content == null) {
        // User cancelled picker
        return false;
      }
    }

    emit(state.copyWith(status: DataManagementStatus.loading));
    try {
      await backupRepository.restoreFromJson(content);
      emit(state.copyWith(
        status: DataManagementStatus.success,
        message: 'Data restored successfully from backup.',
      ));
      return true;
    } catch (e) {
      emit(state.copyWith(
        status: DataManagementStatus.failure,
        message: e.toString(),
      ));
      return false;
    }
  }
}
