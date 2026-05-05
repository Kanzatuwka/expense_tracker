import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../categories/providers/categories_provider.dart';
import '../providers/expenses_provider.dart';

class ExpenseCreateScreen extends ConsumerStatefulWidget {
  const ExpenseCreateScreen({super.key});

  @override
  ConsumerState<ExpenseCreateScreen> createState() =>
      _ExpenseCreateScreenState();
}

class _ExpenseCreateScreenState extends ConsumerState<ExpenseCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  String? _selectedCategoryId;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // Datumsauswahl öffnen
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

  // Ausgabe speichern
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte eine Kategorie auswählen'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref
          .read(expensesNotifierProvider.notifier)
          .addExpense(
            amount: double.parse(_amountController.text.trim()),
            categoryId: _selectedCategoryId!,
            date: _selectedDate,
            note: _noteController.text.trim(),
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Speichern: $e'),
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
    // Kategorien aus Firestore laden
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Neue Ausgabe')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Betrag Eingabefeld
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Betrag (€)',
                  prefixIcon: Icon(Icons.euro),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Bitte Betrag eingeben';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Ungültiger Betrag';
                  }
                  if (double.parse(value) <= 0) {
                    return 'Betrag muss größer als 0 sein';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Kategorie Dropdown — aus Firestore geladen
              categoriesAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Fehler: $e'),
                data: (categories) => DropdownButtonFormField<String>(
                  initialValue: _selectedCategoryId,
                  decoration: const InputDecoration(
                    labelText: 'Kategorie',
                    prefixIcon: Icon(Icons.category_outlined),
                    border: OutlineInputBorder(),
                  ),
                  hint: const Text('Kategorie auswählen'),
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
              // Datumsauswahl
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today_outlined),
                title: const Text('Datum'),
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
              // Notiz Eingabefeld
              TextFormField(
                controller: _noteController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notiz (optional)',
                  prefixIcon: Icon(Icons.note_outlined),
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 24),
              // Speichern Button
              FilledButton(
                onPressed: _isLoading ? null : _save,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Speichern'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
