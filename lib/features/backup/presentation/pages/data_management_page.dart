import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/data_management_cubit.dart';
import '../cubit/data_management_state.dart';

class DataManagementPage extends StatelessWidget {
  final VoidCallback? onRestoreCompleted;

  const DataManagementPage({
    super.key,
    this.onRestoreCompleted,
  });

  void _showRestoreConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Restore Database Backup?'),
        content: const Text(
          'This action will overwrite your current accounts, categories, transactions, budgets, '
          'and savings goals with the backup data. Any data not in the backup will be lost.\n\n'
          'Are you sure you want to proceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final success = await context.read<DataManagementCubit>().restoreFromSelectedFile();
              if (success && onRestoreCompleted != null) {
                onRestoreCompleted!();
              }
            },
            child: const Text('Proceed with Restore'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Backup & Export'),
      ),
      body: BlocConsumer<DataManagementCubit, DataManagementState>(
        listener: (context, state) {
          if (state.status == DataManagementStatus.success && state.message != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message!),
                backgroundColor: theme.colorScheme.primary,
              ),
            );
          } else if (state.status == DataManagementStatus.failure && state.message != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message!),
                backgroundColor: theme.colorScheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state.status == DataManagementStatus.loading;

          return Stack(
            children: [
              ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                children: [
                  if (state.status == DataManagementStatus.failure && state.message != null) ...[
                    Card(
                      color: theme.colorScheme.errorContainer,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: theme.colorScheme.onErrorContainer),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                state.message!,
                                style: TextStyle(color: theme.colorScheme.onErrorContainer),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // Card 1: Full Database Backup Snapshot
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: theme.colorScheme.outlineVariant.withAlpha(120)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: theme.colorScheme.primaryContainer,
                                child: Icon(Icons.backup, color: theme.colorScheme.onPrimaryContainer),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Database Backup Snapshot',
                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Export or restore an atomic JSON backup of all accounts, categories, transactions, '
                            'budgets, and savings goals with SHA-256 integrity verification.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: isLoading ? null : () => context.read<DataManagementCubit>().exportBackup(),
                                  icon: const Icon(Icons.upload),
                                  label: const Text('Export Backup'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: isLoading ? null : () => _showRestoreConfirmationDialog(context),
                                  icon: const Icon(Icons.restore),
                                  label: const Text('Restore from Backup'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Card 2: Transactions CSV Export
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: theme.colorScheme.outlineVariant.withAlpha(120)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: theme.colorScheme.secondaryContainer,
                                child: Icon(Icons.table_chart, color: theme.colorScheme.onSecondaryContainer),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Spreadsheet Export',
                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Export all recorded transactions into a standardized RFC 4180 CSV spreadsheet '
                            'compatible with Microsoft Excel, Google Sheets, and financial tools.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.tonalIcon(
                              onPressed:
                                  isLoading ? null : () => context.read<DataManagementCubit>().exportTransactionsCsv(),
                              icon: const Icon(Icons.description_outlined),
                              label: const Text('Export Transactions (CSV)'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (isLoading)
                Container(
                  color: Colors.black.withAlpha(80),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
