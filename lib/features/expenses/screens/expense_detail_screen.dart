import 'package:expense_tracker/core/widgets/category_icon.dart';
import 'package:expense_tracker/features/categories/utils/category_display.dart';
import 'package:expense_tracker/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../categories/models/category.dart';
import '../models/expense.dart';
import '../providers/expenses_provider.dart';
import 'expense_form_screen.dart';

class ExpenseDetailScreen extends ConsumerWidget {
  final Expense expense;
  final Category? category;

  const ExpenseDetailScreen({super.key, required this.expense, this.category});

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteExpenseQuestion),
        content: Text(l10n.deleteExpenseDescription),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref
          .read(expensesNotifierProvider.notifier)
          .deleteExpense(expense.id);
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.detailsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: l10n.editTooltip,
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ExpenseFormScreen(existing: expense),
                ),
              );
              if (context.mounted) Navigator.of(context).pop();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            color: Colors.red,
            tooltip: l10n.deleteTooltip,
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                '${expense.amount.toStringAsFixed(2)} €',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _DetailRow(
                      icon: iconDataForCategory(category?.icon),
                      label: l10n.categoryLabel,
                      value: category != null
                          ? localizedCategoryName(context, category!)
                          : l10n.unknownCategory,
                    ),
                    const Divider(),
                    _DetailRow(
                      icon: Icons.calendar_today_outlined,
                      label: l10n.dateLabel,
                      value:
                          '${expense.date.day}.${expense.date.month}.${expense.date.year}',
                    ),
                    if (expense.note.isNotEmpty) ...[
                      const Divider(),
                      _DetailRow(
                        icon: Icons.note_outlined,
                        label: l10n.noteLabel,
                        value: expense.note,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(color: Theme.of(context).colorScheme.secondary),
          ),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
