import 'package:expense_tracker/features/categories/providers/categories_provider.dart';
import 'package:expense_tracker/features/expenses/models/expense.dart';
import 'package:expense_tracker/features/expenses/providers/expenses_provider.dart';
import 'package:expense_tracker/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ExpenseFormScreen extends ConsumerStatefulWidget {
  final Expense? existing;

  const ExpenseFormScreen({super.key, this.existing});

  @override
  ConsumerState<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends ConsumerState<ExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  String? _selectedCategoryId;
  late DateTime _selectedDate;
  bool _isLoading = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _amountController.text = existing.amount.toString();
      _noteController.text = existing.note;
      _selectedCategoryId = existing.categoryId;
      _selectedDate = existing.date;
    } else {
      _selectedDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
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
      final amount = double.parse(_amountController.text.trim());
      final note = _noteController.text.trim();
      final notifier = ref.read(expensesNotifierProvider.notifier);

      if (_isEdit) {
        await notifier.updateExpense(
          id: widget.existing!.id,
          amount: amount,
          categoryId: _selectedCategoryId!,
          date: _selectedDate,
          note: note,
        );
      } else {
        await notifier.addExpense(
          amount: amount,
          categoryId: _selectedCategoryId!,
          date: _selectedDate,
          note: note,
        );
      }
      if (mounted) Navigator.of(context).pop();
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? l10n.editExpense : l10n.newExpense),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: l10n.amountLabel,
                  prefixIcon: const Icon(Icons.euro),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.pleaseEnterAmount;
                  }
                  if (double.tryParse(value) == null) {
                    return l10n.invalidAmount;
                  }
                  if (double.parse(value) <= 0) {
                    return l10n.amountMustBePositive;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              categoriesAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text(l10n.errorPrefix(e)),
                data: (categories) => DropdownButtonFormField<String>(
                  initialValue: _selectedCategoryId,
                  decoration: InputDecoration(
                    labelText: l10n.categoryLabel,
                    prefixIcon: const Icon(Icons.category_outlined),
                    border: const OutlineInputBorder(),
                  ),
                  hint: Text(l10n.categoryHint),
                  items: categories.map((category) {
                    return DropdownMenuItem(
                      value: category.id,
                      child: Text(category.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedCategoryId = value);
                  },
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today_outlined),
                title: Text(l10n.dateLabel),
                subtitle: Text(
                  '${_selectedDate.day}.${_selectedDate.month}.${_selectedDate.year}',
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey.shade400),
                ),
                onTap: _pickDate,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: l10n.noteOptional,
                  prefixIcon: const Icon(Icons.note_outlined),
                  border: const OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isLoading ? null : _save,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
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
                    : Text(_isEdit ? l10n.update : l10n.save),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
