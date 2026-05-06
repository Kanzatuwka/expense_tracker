import 'package:expense_tracker/features/categories/models/category.dart';
import 'package:expense_tracker/features/categories/providers/categories_provider.dart';
import 'package:expense_tracker/features/categories/utils/category_display.dart';
import 'package:expense_tracker/features/expenses/models/expense.dart';
import 'package:expense_tracker/features/expenses/providers/expenses_provider.dart';
import 'package:expense_tracker/l10n/generated/app_localizations.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

const _chartColors = [
  Color(0xFF2196F3),
  Color(0xFF4CAF50),
  Color(0xFFFF9800),
  Color(0xFFE91E63),
  Color(0xFF9C27B0),
  Color(0xFF00BCD4),
  Color(0xFFFF5722),
  Color(0xFF607D8B),
];

class ChartScreen extends ConsumerStatefulWidget {
  const ChartScreen({super.key});

  @override
  ConsumerState<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends ConsumerState<ChartScreen> {
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
      appBar: AppBar(title: Text(l10n.chartsTitle)),
      body: expensesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.errorPrefix(e))),
        data: (expenses) => categoriesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text(l10n.errorPrefix(e))),
          data: (categories) => _ChartBody(
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

class _ChartBody extends StatelessWidget {
  final List<Expense> expenses;
  final List<Category> categories;
  final DateTime selectedMonth;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;

  const _ChartBody({
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
    final monthLabel = DateFormat('MMMM yyyy', locale).format(selectedMonth);
    final now = DateTime.now();
    final isCurrentMonth =
        selectedMonth.year == now.year && selectedMonth.month == now.month;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    final monthExpenses = expenses
        .where((e) =>
            e.date.year == selectedMonth.year &&
            e.date.month == selectedMonth.month)
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
        _SectionHeader(text: l10n.byCategorySection),
        const SizedBox(height: 12),
        if (monthExpenses.isEmpty)
          SizedBox(
            height: 160,
            child: Center(
              child: Text(
                l10n.noExpenses,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          _PieChartCard(expenses: monthExpenses, categories: categories),
        const SizedBox(height: 24),
        _SectionHeader(text: l10n.monthlyTrendSection),
        const SizedBox(height: 12),
        _BarChartCard(expenses: expenses, selectedMonth: selectedMonth),
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

class _PieChartCard extends StatelessWidget {
  final List<Expense> expenses;
  final List<Category> categories;

  const _PieChartCard({required this.expenses, required this.categories});

  @override
  Widget build(BuildContext context) {
    final totals = <String, double>{};
    for (final e in expenses) {
      totals[e.categoryId] = (totals[e.categoryId] ?? 0) + e.amount;
    }
    final total = totals.values.fold(0.0, (a, b) => a + b);

    final entries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final sections = entries.indexed
        .map((item) {
          final (i, entry) = item;
          final pct = entry.value / total * 100;
          return PieChartSectionData(
            value: entry.value,
            color: _chartColors[i % _chartColors.length],
            title: '${pct.toStringAsFixed(0)}%',
            titleStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            radius: 80,
          );
        })
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 220,
          child: PieChart(
            PieChartData(sections: sections, sectionsSpace: 2),
          ),
        ),
        const SizedBox(height: 16),
        ...entries.indexed.map((item) {
          final (i, entry) = item;
          final category =
              categories.where((c) => c.id == entry.key).firstOrNull;
          final name = category != null
              ? localizedCategoryName(context, category)
              : entry.key;
          final pct = entry.value / total * 100;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _chartColors[i % _chartColors.length],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(name)),
                Text(
                  '${pct.toStringAsFixed(1)}%',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 12),
                Text(
                  '${entry.value.toStringAsFixed(2)} €',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _BarChartCard extends StatelessWidget {
  final List<Expense> expenses;
  final DateTime selectedMonth;

  const _BarChartCard({
    required this.expenses,
    required this.selectedMonth,
  });

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final scheme = Theme.of(context).colorScheme;

    final months = List.generate(
      6,
      (i) => DateTime(selectedMonth.year, selectedMonth.month - 5 + i),
    );

    final totals = months.map((m) {
      return expenses
          .where((e) => e.date.year == m.year && e.date.month == m.month)
          .fold(0.0, (sum, e) => sum + e.amount);
    }).toList();

    final maxVal = totals.reduce((a, b) => a > b ? a : b);
    final maxY = maxVal <= 0 ? 100.0 : maxVal * 1.25;

    final barGroups = List.generate(6, (i) {
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: totals[i],
            color: scheme.primary,
            width: 22,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    });

    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          barGroups: barGroups,
          maxY: maxY,
          groupsSpace: 12,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: scheme.outlineVariant,
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 52,
                getTitlesWidget: (value, meta) {
                  if (value == meta.max) return const SizedBox.shrink();
                  return Text(
                    value.toStringAsFixed(0),
                    style: TextStyle(
                      fontSize: 10,
                      color: scheme.onSurfaceVariant,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= months.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      DateFormat('MMM', locale).format(months[idx]),
                      style: TextStyle(
                        fontSize: 10,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (_, _, rod, _) => BarTooltipItem(
                '${rod.toY.toStringAsFixed(2)} €',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
