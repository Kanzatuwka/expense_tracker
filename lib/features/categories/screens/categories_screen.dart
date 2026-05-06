import 'package:expense_tracker/core/widgets/category_icon.dart';
import 'package:expense_tracker/features/categories/models/category.dart';
import 'package:expense_tracker/features/categories/providers/categories_provider.dart';
import 'package:expense_tracker/features/categories/screens/category_create_screen.dart';
import 'package:expense_tracker/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.categoriesTitle)),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.errorPrefix(e))),
        data: (categories) => _CategoriesList(categories: categories),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const CategoryCreateScreen(),
          ),
        ),
        tooltip: l10n.newCategoryTooltip,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _CategoriesList extends StatelessWidget {
  final List<Category> categories;

  const _CategoriesList({required this.categories});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (categories.isEmpty) {
      return _EmptyState();
    }

    final defaults = categories.where((c) => c.isDefault).toList();
    final customs = categories.where((c) => c.isCustom).toList();

    return ListView(
      padding: const EdgeInsets.only(bottom: 80),
      children: [
        if (defaults.isNotEmpty) ...[
          _SectionHeader(text: l10n.defaultCategoriesSection),
          ...defaults.map((c) => _CategoryTile(category: c)),
        ],
        if (customs.isNotEmpty) ...[
          _SectionHeader(text: l10n.customCategoriesSection),
          ...customs.map((c) => _CategoryTile(category: c)),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader({required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: scheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _CategoryTile extends ConsumerWidget {
  final Category category;

  const _CategoryTile({required this.category});

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteCategoryQuestion),
        content: Text(l10n.deleteCategoryDescription(category.name)),
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

    if (confirmed == true) {
      await ref
          .read(categoriesNotifierProvider.notifier)
          .deleteCategory(category.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return ListTile(
      leading: CategoryAvatar(iconName: category.icon),
      title: Text(category.name),
      trailing: category.isCustom
          ? IconButton(
              icon: const Icon(Icons.delete_outline),
              color: Colors.red,
              tooltip: l10n.deleteTooltip,
              onPressed: () => _confirmDelete(context, ref),
            )
          : null,
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.category_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            l10n.noCategoriesYet,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.tapPlusToCreate,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
