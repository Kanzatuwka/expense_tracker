import 'package:expense_tracker/features/categories/models/category.dart';
import 'package:expense_tracker/features/categories/providers/categories_provider.dart';
import 'package:expense_tracker/features/categories/utils/category_display.dart';
import 'package:expense_tracker/features/expenses/models/expense.dart';
import 'package:expense_tracker/features/expenses/providers/expenses_provider.dart';
import 'package:expense_tracker/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

const _topColors = [
  Color(0xFF2196F3),
  Color(0xFF4CAF50),
  Color(0xFFFF9800),
  Color(0xFFE91E63),
  Color(0xFF9C27B0),
];

class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key});

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  void _prevMonth() => setState(
        () => _selectedMonth =
            DateTime(_selectedMonth.year, _selectedMonth.month - 1),
      );

  void _nextMonth() => setState(
        () => _selectedMonth =
            DateTime(_selectedMonth.year, _selectedMonth.month + 1),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final expensesAsync = ref.watch(expensesProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.reportsTitle)),
      body: expensesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.errorPrefix(e))),
        data: (expenses) => categoriesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text(l10n.errorPrefix(e))),
          data: (categories) => _ReportBody(
            expenses: expenses,
            categories: categories,
            selectedMonth: _selectedMonth,
            onPrevMonth: _prevMonth,
            onNextMonth: _nextMonth,
          ),
        ),
      ),
    );
  }
}

class _ReportBody extends StatelessWidget {
  final List<Expense> expenses;
  final List<Category> categories;
  final DateTime selectedMonth;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;

  const _ReportBody({
    required this.expenses,
    required this.categories,
    required this.selectedMonth,
    required this.onPrevMonth,
    required this.onNextMonth,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final raw = DateFormat('LLLL yyyy', locale).format(selectedMonth);
    final monthLabel = raw[0].toUpperCase() + raw.substring(1);
    final now = DateTime.now();
    final isCurrentMonth =
        selectedMonth.year == now.year && selectedMonth.month == now.month;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    final prevMonth = DateTime(selectedMonth.year, selectedMonth.month - 1);
    final monthExpenses = expenses
        .where((e) =>
            e.date.year == selectedMonth.year &&
            e.date.month == selectedMonth.month)
        .toList();
    final prevMonthExpenses = expenses
        .where(
            (e) => e.date.year == prevMonth.year && e.date.month == prevMonth.month)
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(Icons.chevron_left, color: onSurface),
              onPressed: onPrevMonth,
            ),
            Text(
              monthLabel,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            isCurrentMonth
                ? const SizedBox(width: 48)
                : IconButton(
                    icon: Icon(Icons.chevron_right, color: onSurface),
                    onPressed: onNextMonth,
                  ),
          ],
        ),
        const SizedBox(height: 8),
        _SectionHeader(text: l10n.summarySection),
        const SizedBox(height: 12),
        _SummaryCard(
          monthExpenses: monthExpenses,
          prevMonthExpenses: prevMonthExpenses,
          selectedMonth: selectedMonth,
          l10n: l10n,
        ),
        const SizedBox(height: 24),
        _SectionHeader(text: l10n.topCategoriesSection),
        const SizedBox(height: 12),
        if (monthExpenses.isEmpty)
          SizedBox(
            height: 80,
            child: Center(
              child: Text(
                l10n.noDataForMonth,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          _TopCategoriesList(
            expenses: monthExpenses,
            categories: categories,
          ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final List<Expense> monthExpenses;
  final List<Expense> prevMonthExpenses;
  final DateTime selectedMonth;
  final AppLocalizations l10n;

  const _SummaryCard({
    required this.monthExpenses,
    required this.prevMonthExpenses,
    required this.selectedMonth,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final total = monthExpenses.fold(0.0, (sum, e) => sum + e.amount);
    final prevTotal = prevMonthExpenses.fold(0.0, (sum, e) => sum + e.amount);

    final delta = total - prevTotal;
    final hasPrevData = prevTotal > 0;
    final pct = hasPrevData ? delta / prevTotal * 100 : null;
    final deltaPrefix = delta > 0 ? '+' : '';
    final pctSuffix = pct != null ? ' ($deltaPrefix${pct.toStringAsFixed(0)}%)' : '';
    final deltaText = '$deltaPrefix${delta.toStringAsFixed(2)} €$pctSuffix';
    final deltaColor = delta < 0
        ? Colors.green.shade600
        : delta > 0
            ? Colors.red.shade600
            : scheme.onSurfaceVariant;

    final now = DateTime.now();
    final daysInMonth =
        DateTime(selectedMonth.year, selectedMonth.month + 1, 0).day;
    final daysElapsed =
        (selectedMonth.year == now.year && selectedMonth.month == now.month)
            ? now.day
            : daysInMonth;
    final dailyAvg = daysElapsed > 0 ? total / daysElapsed : 0.0;

    return Card(
      elevation: 0,
      color: scheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${total.toStringAsFixed(2)} €',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: scheme.onSurface,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    label: l10n.vsLastMonth,
                    value: hasPrevData || delta != 0 ? deltaText : '—',
                    valueColor: hasPrevData || delta != 0
                        ? deltaColor
                        : scheme.onSurfaceVariant,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    label: l10n.dailyAvgLabel,
                    value: '${dailyAvg.toStringAsFixed(2)} €',
                    valueColor: scheme.onSurface,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _StatItem({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: valueColor,
              ),
        ),
      ],
    );
  }
}

class _TopCategoriesList extends StatelessWidget {
  final List<Expense> expenses;
  final List<Category> categories;

  const _TopCategoriesList({
    required this.expenses,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    final totals = <String, double>{};
    for (final e in expenses) {
      totals[e.categoryId] = (totals[e.categoryId] ?? 0) + e.amount;
    }
    final grandTotal = totals.values.fold(0.0, (a, b) => a + b);

    final entries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = entries.take(5).toList();

    return Column(
      children: top.indexed.map((item) {
        final (i, entry) = item;
        final category =
            categories.where((c) => c.id == entry.key).firstOrNull;
        final name = category != null
            ? localizedCategoryName(context, category)
            : entry.key;
        final pct = grandTotal > 0 ? entry.value / grandTotal : 0.0;
        final color = _topColors[i % _topColors.length];

        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: pct,
                      backgroundColor:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      color: color,
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${entry.value.toStringAsFixed(2)} €',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${(pct * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
