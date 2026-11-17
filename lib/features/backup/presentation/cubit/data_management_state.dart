import 'package:equatable/equatable.dart';

enum DataManagementStatus { initial, loading, success, failure }

class DataManagementState extends Equatable {
  final DataManagementStatus status;
  final String? message;
  final String? exportedFilePath;

  const DataManagementState({
    this.status = DataManagementStatus.initial,
    this.message,
    this.exportedFilePath,
  });

  DataManagementState copyWith({
    DataManagementStatus? status,
    String? message,
    String? exportedFilePath,
  }) {
    return DataManagementState(
      status: status ?? this.status,
      message: message ?? this.message,
      exportedFilePath: exportedFilePath ?? this.exportedFilePath,
    );
  }

  @override
  List<Object?> get props => [status, message, exportedFilePath];
}
