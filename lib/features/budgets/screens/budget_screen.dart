import 'package:expense_tracker/features/budgets/models/budget.dart';
import 'package:expense_tracker/features/budgets/providers/budgets_provider.dart';
import 'package:expense_tracker/features/categories/models/category.dart';
import 'package:expense_tracker/features/categories/providers/categories_provider.dart';
import 'package:expense_tracker/features/categories/utils/category_display.dart';
import 'package:expense_tracker/features/expenses/providers/expenses_provider.dart';
import 'package:expense_tracker/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final categoriesAsync = ref.watch(categoriesProvider);
    final budgetsAsync = ref.watch(budgetsProvider);
    final expensesAsync = ref.watch(expensesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.budgetsTitle)),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.errorPrefix(e))),
        data: (categories) => budgetsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text(l10n.errorPrefix(e))),
          data: (budgets) {
            final now = DateTime.now();
            final monthlySpending = <String, double>{};
            if (expensesAsync.hasValue) {
              for (final e in expensesAsync.value!) {
                if (e.date.year == now.year && e.date.month == now.month) {
                  monthlySpending[e.categoryId] =
                      (monthlySpending[e.categoryId] ?? 0) + e.amount;
                }
              }
            }

            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: categories.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              // Use '_' to avoid shadowing the outer ConsumerWidget 'context'.
              // The outer context is stable across list rebuilds and is safe
              // to pass to showDialog.
              itemBuilder: (_, i) {
                final category = categories[i];
                final budget = budgets
                    .where((b) => b.categoryId == category.id)
                    .firstOrNull;
                final spent = monthlySpending[category.id] ?? 0.0;
                return _BudgetRow(
                  category: category,
                  budget: budget,
                  spent: spent,
                  onTap: () => _openDialog(context, ref, l10n, category, budget),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _openDialog(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    Category category,
    Budget? existing,
  ) {
    showDialog<void>(
      context: context,
      builder: (_) => _BudgetDialog(
        l10n: l10n,
        category: category,
        existing: existing,
        onSave: (amount) {
          ref.read(budgetsNotifierProvider.notifier).setBudget(
                Budget(categoryId: category.id, amount: amount),
              );
        },
        onDelete: existing != null
            ? () => ref
                .read(budgetsNotifierProvider.notifier)
                .deleteBudget(existing.categoryId)
            : null,
      ),
    );
  }
}

class _BudgetDialog extends StatefulWidget {
  final AppLocalizations l10n;
  final Category category;
  final Budget? existing;
  final ValueChanged<double> onSave;
  final VoidCallback? onDelete;

  const _BudgetDialog({
    required this.l10n,
    required this.category,
    required this.existing,
    required this.onSave,
    required this.onDelete,
  });

  @override
  State<_BudgetDialog> createState() => _BudgetDialogState();
}

class _BudgetDialogState extends State<_BudgetDialog> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.existing != null
          ? widget.existing!.amount.toStringAsFixed(2)
          : '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    return AlertDialog(
      title: Text(
        widget.existing != null ? l10n.editBudgetTitle : l10n.setBudgetTitle,
      ),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          decoration: InputDecoration(
            labelText: l10n.monthlyLimitLabel,
            prefixText: '€ ',
          ),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return l10n.pleaseEnterAmount;
            final parsed = double.tryParse(v.replaceAll(',', '.'));
            if (parsed == null) return l10n.invalidAmount;
            if (parsed <= 0) return l10n.amountMustBePositive;
            return null;
          },
        ),
      ),
      actions: [
        if (widget.onDelete != null)
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              Navigator.of(context).pop();
              widget.onDelete!();
            },
            child: Text(l10n.delete),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            final amount = double.parse(
              _controller.text.trim().replaceAll(',', '.'),
            );
            Navigator.of(context).pop();
            widget.onSave(amount);
          },
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

class _BudgetRow extends StatelessWidget {
  final Category category;
  final Budget? budget;
  final double spent;
  final VoidCallback onTap;

  const _BudgetRow({
    required this.category,
    required this.budget,
    required this.spent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final hasBudget = budget != null;
    final progress = hasBudget ? (spent / budget!.amount).clamp(0.0, 1.0) : 0.0;

    Color progressColor;
    if (!hasBudget) {
      progressColor = scheme.primary;
    } else if (progress >= 1.0) {
      progressColor = Colors.red.shade600;
    } else if (progress >= 0.75) {
      progressColor = Colors.orange.shade600;
    } else {
      progressColor = Colors.green.shade600;
    }

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: scheme.primaryContainer,
        child: Icon(
          _iconData(category.icon),
          color: scheme.onPrimaryContainer,
          size: 20,
        ),
      ),
      title: Text(localizedCategoryName(context, category)),
      subtitle: hasBudget
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: progress,
                  color: progressColor,
                  backgroundColor: scheme.surfaceContainerHighest,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
                const SizedBox(height: 4),
                Text(
                  '${spent.toStringAsFixed(2)} / ${budget!.amount.toStringAsFixed(2)} €',
                  style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                ),
              ],
            )
          : Text(
              l10n.noBudgetSet,
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            ),
      trailing: Icon(
        hasBudget ? Icons.edit_outlined : Icons.add,
        color: scheme.onSurfaceVariant,
        size: 20,
      ),
    );
  }

  IconData _iconData(String? name) {
    return switch (name) {
      'restaurant' => Icons.restaurant,
      'directions_bus' => Icons.directions_bus,
      'favorite' => Icons.favorite,
      'sports_esports' => Icons.sports_esports,
      'category' => Icons.category,
      _ => Icons.label_outline,
    };
  }
}
