import 'package:expense_tracker/core/widgets/category_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../categories/models/category.dart';
import '../models/expense.dart';
import '../providers/expenses_provider.dart';

class ExpenseDetailScreen extends ConsumerWidget {
  final Expense expense;
  final Category? category;

  const ExpenseDetailScreen({super.key, required this.expense, this.category});

  // Löschdialog anzeigen
  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ausgabe löschen?'),
        content: const Text('Diese Ausgabe wird unwiderruflich gelöscht.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Löschen'),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            color: Colors.red,
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Betrag
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
            // Detailkarte
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Kategorie mit Icon
                    _DetailRow(
                      icon: iconDataForCategory(category?.icon),
                      label: 'Kategorie',
                      value: category?.name ?? 'Unbekannt',
                    ),
                    const Divider(),
                    _DetailRow(
                      icon: Icons.calendar_today_outlined,
                      label: 'Datum',
                      value:
                          '${expense.date.day}.${expense.date.month}.${expense.date.year}',
                    ),
                    if (expense.note.isNotEmpty) ...[
                      const Divider(),
                      _DetailRow(
                        icon: Icons.note_outlined,
                        label: 'Notiz',
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

// Hilfswidget für eine Detailzeile
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
