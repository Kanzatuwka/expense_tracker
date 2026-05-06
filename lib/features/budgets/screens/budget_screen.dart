import 'package:expense_tracker/core/widgets/category_icon.dart';
import 'package:expense_tracker/features/auth/providers/auth_provider.dart';
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
import 'package:intl/intl.dart';

// ─── Data class for the monthly summary dialog ───────────────────────────────

class _SummaryItem {
  final Category category;
  final double limit;
  final double spent;

  const _SummaryItem({
    required this.category,
    required this.limit,
    required this.spent,
  });
}

// ─── Screen ──────────────────────────────────────────────────────────────────

class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  bool _summaryCheckDone = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final profileAsync = ref.watch(userProfileProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final budgetsAsync = ref.watch(budgetsProvider);
    final expensesAsync = ref.watch(expensesProvider);

    // Once both profile and budgets are loaded, check if summary should show.
    final profile = profileAsync.value;
    final budgets = budgetsAsync.value;
    if (!_summaryCheckDone && profile != null && budgets != null) {
      _summaryCheckDone = true;
      final now = DateTime.now();
      final needsShow =
          profile.lastBudgetSummaryYear != now.year ||
          profile.lastBudgetSummaryMonth != now.month;
      if (needsShow) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (budgets.isNotEmpty) {
            _showMonthlySummary(l10n);
          } else {
            ref.read(budgetSummaryNotifierProvider.notifier).markSummaryShown();
          }
        });
      }
    }

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
                  onTap: () => _openDialog(context, l10n, category, budget),
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

  // Uses `this.context` (State.context) so there is no stale BuildContext
  // parameter captured across the await gap.
  Future<void> _showMonthlySummary(AppLocalizations l10n) async {
    final expenses = ref.read(expensesProvider).value ?? [];
    final currentBudgets = ref.read(budgetsProvider).value ?? [];
    final categories = ref.read(categoriesProvider).value ?? [];

    final now = DateTime.now();
    final prevYear = now.month == 1 ? now.year - 1 : now.year;
    final prevMonth = now.month == 1 ? 12 : now.month - 1;

    // Load the limits that were actually in effect last month.
    final userId = ref.read(authRepositoryProvider).currentUserId;
    Map<String, double> historicalLimits = {};
    if (userId != null) {
      historicalLimits = await ref
          .read(budgetRepositoryProvider)
          .getMonthlySnapshot(userId, prevYear, prevMonth);
    }

    // Prefer historical limit; fall back to current limit for categories
    // whose budget was never explicitly changed (no snapshot written yet).
    final knownCategoryIds = {
      ...currentBudgets.map((b) => b.categoryId),
      ...historicalLimits.keys,
    };

    final prevMonthSpending = <String, double>{};
    for (final expense in expenses) {
      if (expense.date.year == prevYear && expense.date.month == prevMonth) {
        prevMonthSpending[expense.categoryId] =
            (prevMonthSpending[expense.categoryId] ?? 0) + expense.amount;
      }
    }

    final summaryItems = knownCategoryIds
        .map((id) {
          final category = categories.where((c) => c.id == id).firstOrNull;
          if (category == null) return null;
          final limit = historicalLimits[id] ??
              currentBudgets.where((b) => b.categoryId == id).firstOrNull?.amount;
          if (limit == null) return null;
          return _SummaryItem(
            category: category,
            limit: limit,
            spent: prevMonthSpending[id] ?? 0,
          );
        })
        .nonNulls
        .toList();

    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (_) => _BudgetSummaryDialog(
        l10n: l10n,
        items: summaryItems,
        prevYear: prevYear,
        prevMonth: prevMonth,
        onClose: () =>
            ref.read(budgetSummaryNotifierProvider.notifier).markSummaryShown(),
      ),
    );
  }
}

// ─── Budget edit dialog ───────────────────────────────────────────────────────

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

// ─── Monthly summary dialog ───────────────────────────────────────────────────

class _BudgetSummaryDialog extends StatelessWidget {
  final AppLocalizations l10n;
  final List<_SummaryItem> items;
  final int prevYear;
  final int prevMonth;
  final VoidCallback onClose;

  const _BudgetSummaryDialog({
    required this.l10n,
    required this.items,
    required this.prevYear,
    required this.prevMonth,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toString();
    final prevMonthName =
        DateFormat('LLLL y', locale).format(DateTime(prevYear, prevMonth));
    final currentMonthName =
        DateFormat('LLLL y', locale).format(DateTime.now());

    final rows = items.map((item) {
      final progress = (item.spent / item.limit).clamp(0.0, 1.0);
      final exceeded = item.spent > item.limit;
      final progressColor = exceeded
          ? Colors.red.shade600
          : progress >= 0.75
          ? Colors.orange.shade600
          : Colors.green.shade600;

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CategoryAvatar(iconName: item.category.icon, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    localizedCategoryName(context, item.category),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                Icon(
                  exceeded
                      ? Icons.warning_amber_rounded
                      : Icons.check_circle_outline,
                  size: 18,
                  color: exceeded
                      ? Colors.red.shade600
                      : Colors.green.shade600,
                ),
              ],
            ),
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
              '${item.spent.toStringAsFixed(2)} / ${item.limit.toStringAsFixed(2)} €',
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }).toList();

    return AlertDialog(
      title: Text(l10n.budgetSummaryTitle),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                prevMonthName,
                style: TextStyle(
                  fontSize: 13,
                  color: scheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 16),
              ...rows,
              const Divider(height: 24),
              Row(
                children: [
                  Icon(Icons.refresh, size: 16, color: Colors.green.shade600),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      l10n.budgetLimitsRefreshed(currentMonthName),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            onClose();
          },
          child: Text(l10n.close),
        ),
      ],
    );
  }
}

// ─── Budget row ───────────────────────────────────────────────────────────────

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
    final progress =
        hasBudget ? (spent / budget!.amount).clamp(0.0, 1.0) : 0.0;

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
          iconDataForCategory(category.icon),
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
}
