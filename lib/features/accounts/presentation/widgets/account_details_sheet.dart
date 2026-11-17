import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/account.dart';
import '../cubit/accounts_cubit.dart';

class AccountDetailsSheet extends StatefulWidget {
  final Account account;

  const AccountDetailsSheet({super.key, required this.account});

  @override
  State<AccountDetailsSheet> createState() => _AccountDetailsSheetState();
}

class _AccountDetailsSheetState extends State<AccountDetailsSheet> {
  late TextEditingController _nameController;
  late bool _isArchived;
  late String _selectedIcon;
  late int _selectedColor;

  static const List<Map<String, dynamic>> _iconOptions = [
    {'name': 'account_balance', 'icon': Icons.account_balance_outlined},
    {'name': 'savings', 'icon': Icons.savings_outlined},
    {'name': 'credit_card', 'icon': Icons.credit_card_outlined},
    {'name': 'payments', 'icon': Icons.payments_outlined},
    {'name': 'account_balance_wallet', 'icon': Icons.account_balance_wallet_outlined},
  ];

  static const List<int> _colorOptions = [
    0xFF1E3A8A, // Navy
    0xFF10B981, // Emerald
    0xFFEF4444, // Red
    0xFFF59E0B, // Amber
    0xFF8B5CF6, // Purple
    0xFF06B6D4, // Cyan
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.account.name);
    _isArchived = widget.account.isArchived;
    _selectedIcon = widget.account.icon;
    _selectedColor = widget.account.color;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    final updated = widget.account.copyWith(
      name: _nameController.text.trim(),
      icon: _selectedIcon,
      color: _selectedColor,
      isArchived: _isArchived,
    );
    context.read<AccountsCubit>().updateAccount(updated);
    Navigator.of(context).pop();
  }

  void _deleteAccount() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete this account? If this account has transactions, deletion will be blocked and you should archive it instead.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.errorContainer,
            ),
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              context.read<AccountsCubit>().deleteAccount(widget.account.id);
              Navigator.of(context).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Account Details', style: theme.textTheme.titleLarge),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Account Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Current Balance'),
            subtitle: Text(
              widget.account.currentBalance.format(),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Archive Account'),
            subtitle: const Text('Hide this account from daily lists while keeping transactions intact'),
            value: _isArchived,
            onChanged: (val) {
              setState(() {
                _isArchived = val;
              });
            },
          ),
          const SizedBox(height: 16),
          Text('Icon', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _iconOptions.map((opt) {
              final isSelected = _selectedIcon == opt['name'];
              return InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () {
                  setState(() {
                    _selectedIcon = opt['name'] as String;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.surfaceContainerHighest,
                  ),
                  child: Icon(
                    opt['icon'] as IconData,
                    color: isSelected
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Text('Color', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _colorOptions.map((colorVal) {
              final isSelected = _selectedColor == colorVal;
              return InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () {
                  setState(() {
                    _selectedColor = colorVal;
                  });
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Color(colorVal),
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(color: theme.colorScheme.onSurface, width: 3)
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _saveChanges,
            child: const Text('Save Changes'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete Account'),
            onPressed: _deleteAccount,
          ),
        ],
      ),
    ),
  );
  }
}
