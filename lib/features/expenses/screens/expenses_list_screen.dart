import 'package:expense_tracker/core/widgets/category_icon.dart';
import 'package:expense_tracker/features/categories/utils/category_display.dart';
import 'package:expense_tracker/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../categories/models/category.dart';
import '../../categories/providers/categories_provider.dart';
import '../models/expense.dart';
import '../providers/expenses_provider.dart';
import 'expense_detail_screen.dart';

class ExpensesListScreen extends ConsumerStatefulWidget {
  const ExpensesListScreen({super.key});

  @override
  ConsumerState<ExpensesListScreen> createState() => _ExpensesListScreenState();
}

class _ExpensesListScreenState extends ConsumerState<ExpensesListScreen> {
  String? _selectedCategoryId;
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  void _prevMonth() => setState(() {
        _selectedMonth =
            DateTime(_selectedMonth.year, _selectedMonth.month - 1);
      });

  void _nextMonth() => setState(() {
        _selectedMonth =
            DateTime(_selectedMonth.year, _selectedMonth.month + 1);
      });

  Future<bool?> _confirmDeleteDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return showDialog<bool>(
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
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final expensesAsync = ref.watch(expensesProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.expensesTitle)),

      body: expensesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.errorPrefix(e))),
        data: (expenses) {
          final filtered = expenses.where((e) {
            final matchesMonth = e.date.year == _selectedMonth.year &&
                e.date.month == _selectedMonth.month;
            final matchesCategory = _selectedCategoryId == null ||
                e.categoryId == _selectedCategoryId;
            return matchesMonth && matchesCategory;
          }).toList();

          return Column(
            children: [
              _TotalSummary(
                expenses: filtered,
                selectedMonth: _selectedMonth,
                onPrevMonth: _prevMonth,
                onNextMonth: _nextMonth,
              ),
              categoriesAsync.when(
                loading: () => const SizedBox(height: 48),
                error: (e, _) => const SizedBox(height: 48),
                data: (categories) => _CategoryFilter(
                  categories: categories,
                  selectedCategoryId: _selectedCategoryId,
                  onCategorySelected: (id) {
                    setState(() => _selectedCategoryId = id);
                  },
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.receipt_long_outlined,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              l10n.noExpenses,
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final expense = filtered[index];
                          final category = categoriesAsync.value
                              ?.where((c) => c.id == expense.categoryId)
                              .firstOrNull;
                          return Dismissible(
                            key: ValueKey(expense.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              color: Colors.red,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                            ),
                            confirmDismiss: (_) =>
                                _confirmDeleteDialog(context),
                            onDismissed: (_) async {
                              await ref
                                  .read(expensesNotifierProvider.notifier)
                                  .deleteExpense(expense.id);
                            },
                            child: _ExpenseListTile(
                              expense: expense,
                              category: category,
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CategoryFilter extends StatelessWidget {
  final List<Category> categories;
  final String? selectedCategoryId;
  final ValueChanged<String?> onCategorySelected;

  const _CategoryFilter({
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(l10n.filterAll),
              selected: selectedCategoryId == null,
              onSelected: (_) => onCategorySelected(null),
            ),
          ),
          ...categories.map((category) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(localizedCategoryName(context, category)),
                selected: selectedCategoryId == category.id,
                onSelected: (_) => onCategorySelected(
                  selectedCategoryId == category.id ? null : category.id,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _TotalSummary extends StatelessWidget {
  final List<Expense> expenses;
  final DateTime selectedMonth;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;

  const _TotalSummary({
    required this.expenses,
    required this.selectedMonth,
    required this.onPrevMonth,
    required this.onNextMonth,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final total = expenses.fold(0.0, (sum, e) => sum + e.amount);
    final locale = Localizations.localeOf(context).toString();
    final monthLabel = DateFormat('MMMM yyyy', locale).format(selectedMonth);
    final now = DateTime.now();
    final isCurrentMonth =
        selectedMonth.year == now.year && selectedMonth.month == now.month;
    final onContainer = Theme.of(context).colorScheme.onPrimaryContainer;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.chevron_left, color: onContainer),
                onPressed: onPrevMonth,
              ),
              Text(
                monthLabel,
                style: TextStyle(
                  color: onContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
              isCurrentMonth
                  ? const SizedBox(width: 48)
                  : IconButton(
                      icon: Icon(Icons.chevron_right, color: onContainer),
                      onPressed: onNextMonth,
                    ),
            ],
          ),
          Text(l10n.totalAmount, style: TextStyle(color: onContainer)),
          const SizedBox(height: 4),
          Text(
            '${total.toStringAsFixed(2)} €',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: onContainer,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpenseListTile extends StatelessWidget {
  final Expense expense;
  final Category? category;

  const _ExpenseListTile({required this.expense, required this.category});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListTile(
      leading: CategoryAvatar(iconName: category?.icon),
      title: Text(
        category != null
            ? localizedCategoryName(context, category!)
            : l10n.unknownCategory,
      ),
      subtitle: Text(
        expense.note.isNotEmpty
            ? expense.note
            : '${expense.date.day}.${expense.date.month}.${expense.date.year}',
      ),
      trailing: Text(
        '${expense.amount.toStringAsFixed(2)} €',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              ExpenseDetailScreen(expense: expense, category: category),
        ),
      ),
    );
  }
}
