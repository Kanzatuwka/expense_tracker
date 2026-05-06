import 'package:expense_tracker/core/widgets/category_icon.dart';
import 'package:expense_tracker/features/categories/providers/categories_provider.dart';
import 'package:expense_tracker/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CategoryCreateScreen extends ConsumerStatefulWidget {
  const CategoryCreateScreen({super.key});

  @override
  ConsumerState<CategoryCreateScreen> createState() =>
      _CategoryCreateScreenState();
}

class _CategoryCreateScreenState extends ConsumerState<CategoryCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  String? _selectedIcon;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    if (_selectedIcon == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.pleaseSelectIcon),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref
          .read(categoriesNotifierProvider.notifier)
          .addCategory(
            name: _nameController.text.trim(),
            icon: _selectedIcon!,
          );
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
    return Scaffold(
      appBar: AppBar(title: Text(l10n.newCategoryTitle)),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: l10n.nameLabel,
                  prefixIcon: const Icon(Icons.label_outline),
                  border: const OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.pleaseEnterName;
                  }
                  if (value.trim().length > 30) {
                    return l10n.nameTooLong;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Text(
                l10n.chooseIcon,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _IconPicker(
                selected: _selectedIcon,
                onSelect: (icon) => setState(() => _selectedIcon = icon),
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
                    : Text(l10n.save),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconPicker extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onSelect;

  const _IconPicker({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: kCategoryIcons.entries.map((entry) {
        final iconName = entry.key;
        final iconData = entry.value;
        final isSelected = selected == iconName;

        return InkWell(
          key: ValueKey('icon_$iconName'),
          onTap: () => onSelect(iconName),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? scheme.primaryContainer
                  : scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: scheme.primary, width: 2)
                  : null,
            ),
            child: Icon(
              iconData,
              size: 28,
              color: isSelected
                  ? scheme.onPrimaryContainer
                  : scheme.onSurfaceVariant,
            ),
          ),
        );
      }).toList(),
    );
  }
}
