import 'package:expense_tracker/core/widgets/category_icon.dart';
import 'package:expense_tracker/features/budgets/providers/budgets_provider.dart';
import 'package:expense_tracker/features/categories/models/category.dart';
import 'package:expense_tracker/features/categories/providers/categories_provider.dart';
import 'package:expense_tracker/features/categories/utils/category_display.dart';
import 'package:expense_tracker/features/categorization/categorization_provider.dart';
import 'package:expense_tracker/features/expenses/models/expense.dart';
import 'package:expense_tracker/features/expenses/providers/expenses_provider.dart';
import 'package:expense_tracker/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum _DateMode { today, yesterday, other }

class ExpenseFormScreen extends ConsumerStatefulWidget {
  final Expense? existing;

  const ExpenseFormScreen({super.key, this.existing});

  @override
  ConsumerState<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends ConsumerState<ExpenseFormScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  String? _selectedCategoryId;
  bool _isSuggested = false;
  late DateTime _selectedDate;
  late _DateMode _dateMode;
  double _parsedAmount = 0;
  bool _isLoading = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _amountController.text = existing.amount.toStringAsFixed(2);
      _parsedAmount = existing.amount;
      _noteController.text = existing.note;
      _selectedCategoryId = existing.categoryId;
      _selectedDate = existing.date;
      _dateMode = _dateModeFromDate(existing.date);
    } else {
      _selectedDate = DateTime.now();
      _dateMode = _DateMode.today;
    }
    _amountController.addListener(_onAmountChanged);
    _noteController.addListener(_onNoteChanged);
  }

  _DateMode _dateModeFromDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final d = DateTime(date.year, date.month, date.day);
    if (d == today) return _DateMode.today;
    if (d == yesterday) return _DateMode.yesterday;
    return _DateMode.other;
  }

  void _onAmountChanged() {
    final parsed =
        double.tryParse(_amountController.text.trim().replaceAll(',', '.')) ??
        0;
    if (parsed != _parsedAmount) setState(() => _parsedAmount = parsed);
  }

  void _onNoteChanged() {
    if (!_isSuggested && _selectedCategoryId != null) return;
    final categories = ref.read(categoriesProvider).value;
    if (categories == null) return;
    final service = ref.read(categorizationServiceProvider);
    final suggestion = service.suggestCategoryId(
      _noteController.text,
      categories,
    );
    setState(() {
      _selectedCategoryId = suggestion;
      _isSuggested = suggestion != null;
    });
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _noteController.removeListener(_onNoteChanged);
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _addAmount(int value) {
    final current =
        double.tryParse(
          _amountController.text.trim().replaceAll(',', '.'),
        ) ??
        0;
    _amountController.text = (current + value).toStringAsFixed(2);
  }

  Future<void> _onDateModeSelected(_DateMode mode) async {
    if (mode == _DateMode.other) {
      final picked = await showDatePicker(
        context: context,
        initialDate:
            _dateMode == _DateMode.other ? _selectedDate : DateTime.now(),
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
      );
      if (picked != null && mounted) {
        final now = DateTime.now();
        setState(() {
          _dateMode = _DateMode.other;
          _selectedDate = DateTime(
            picked.year, picked.month, picked.day,
            now.hour, now.minute, now.second,
          );
        });
      }
    } else {
      final now = DateTime.now();
      setState(() {
        _dateMode = mode;
        _selectedDate =
            mode == _DateMode.today
                ? now
                : now.subtract(const Duration(days: 1));
      });
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.pleaseSelectCategory),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final notifier = ref.read(expensesNotifierProvider.notifier);
      if (_isEdit) {
        await notifier.updateExpense(
          id: widget.existing!.id,
          amount: _parsedAmount,
          categoryId: _selectedCategoryId!,
          date: _selectedDate,
          note: _noteController.text.trim(),
        );
      } else {
        await notifier.addExpense(
          amount: _parsedAmount,
          categoryId: _selectedCategoryId!,
          date: _selectedDate,
          note: _noteController.text.trim(),
        );
      }
      if (mounted) {
        _checkBudgetThreshold(
          context,
          _selectedCategoryId!,
          _parsedAmount,
          _selectedDate,
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorSaving(e)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _checkBudgetThreshold(
    BuildContext context,
    String categoryId,
    double newAmount,
    DateTime date,
  ) {
    final now = DateTime.now();
    if (date.year != now.year || date.month != now.month) return;
    final budgets = ref.read(budgetsProvider).value ?? [];
    final budget =
        budgets.where((b) => b.categoryId == categoryId).firstOrNull;
    if (budget == null) return;
    final expenses = ref.read(expensesProvider).value ?? [];
    var spent = expenses
        .where(
          (e) =>
              e.categoryId == categoryId &&
              e.date.year == now.year &&
              e.date.month == now.month,
        )
        .fold(0.0, (sum, e) => sum + e.amount);
    if (_isEdit) {
      final old = widget.existing!;
      if (old.categoryId == categoryId &&
          old.date.year == now.year &&
          old.date.month == now.month) {
        spent -= old.amount;
      }
    }
    final newTotal = spent + newAmount;
    final percent = (newTotal / budget.amount * 100).round();
    final l10n = AppLocalizations.of(context)!;
    final categories = ref.read(categoriesProvider).value ?? [];
    final category = categories.where((c) => c.id == categoryId).firstOrNull;
    final categoryName =
        category != null ? localizedCategoryName(context, category) : categoryId;
    if (newTotal >= budget.amount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.budgetExceeded(categoryName)),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } else if (percent >= 75) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.budgetWarning(categoryName, percent)),
          backgroundColor: Colors.orange.shade700,
        ),
      );
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? l10n.editExpense : l10n.newExpense)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildAmountSection(l10n, scheme),
            const SizedBox(height: 28),
            categoriesAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text(l10n.errorPrefix(e)),
              data: (categories) => _buildCategorySection(l10n, scheme, categories),
            ),
            const SizedBox(height: 28),
            _buildDateSection(l10n, scheme),
            const SizedBox(height: 28),
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: l10n.noteOptional,
                hintText: l10n.addDescriptionHint,
                prefixIcon: const Icon(Icons.note_outlined),
                border: const OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: (_parsedAmount <= 0 || _isLoading) ? null : _save,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      _isEdit ? l10n.update : l10n.save,
                      style: const TextStyle(fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountSection(AppLocalizations l10n, ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.amountLabel,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        TextField(
          controller: _amountController,
          autofocus: !_isEdit,
          textAlign: TextAlign.center,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          style: TextStyle(
            fontSize: 52,
            fontWeight: FontWeight.bold,
            color: scheme.onSurface,
          ),
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: '0.00',
            hintStyle: TextStyle(
              fontSize: 52,
              fontWeight: FontWeight.bold,
              color: scheme.outlineVariant,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [5, 10, 20, 50].map((v) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ActionChip(
                label: Text('+$v'),
                onPressed: () => _addAmount(v),
                visualDensity: VisualDensity.compact,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCategorySection(
    AppLocalizations l10n,
    ColorScheme scheme,
    List<Category> categories,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.categoryLabel,
          style: TextStyle(
            fontSize: 12,
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.9,
          ),
          itemCount: categories.length,
          itemBuilder: (_, i) {
            final cat = categories[i];
            return _CategoryChip(
              category: cat,
              isSelected: cat.id == _selectedCategoryId,
              scheme: scheme,
              onTap: () => setState(() {
                _selectedCategoryId = cat.id;
                _isSuggested = false;
              }),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDateSection(AppLocalizations l10n, ColorScheme scheme) {
    final d = _selectedDate;
    final formattedDate =
        '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.dateLabel,
          style: TextStyle(
            fontSize: 12,
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        SegmentedButton<_DateMode>(
          showSelectedIcon: false,
          expandedInsets: EdgeInsets.zero,
          segments: [
            ButtonSegment(
              value: _DateMode.today,
              label: Text(l10n.dateToday),
            ),
            ButtonSegment(
              value: _DateMode.yesterday,
              label: Text(l10n.dateYesterday),
            ),
            ButtonSegment(
              value: _DateMode.other,
              label: Text(
                _dateMode == _DateMode.other ? formattedDate : l10n.dateOther,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          selected: {_dateMode},
          onSelectionChanged: (s) => _onDateModeSelected(s.first),
        ),
        // When already on "other", let user tap the date to reopen picker.
        if (_dateMode == _DateMode.other) ...[
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: () => _onDateModeSelected(_DateMode.other),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.edit_calendar_outlined,
                      size: 13,
                      color: scheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      l10n.dateOther,
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Category chip ────────────────────────────────────────────────────────────

class _CategoryChip extends StatelessWidget {
  final Category category;
  final bool isSelected;
  final ColorScheme scheme;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.category,
    required this.isSelected,
    required this.scheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? scheme.primaryContainer : scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              iconDataForCategory(category.icon),
              color: isSelected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
              size: 22,
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                localizedCategoryName(context, category),
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected
                      ? scheme.onPrimaryContainer
                      : scheme.onSurfaceVariant,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
