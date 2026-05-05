import 'package:expense_tracker/core/widgets/category_icon.dart';
import 'package:expense_tracker/features/categories/models/category.dart';
import 'package:expense_tracker/features/categories/providers/categories_provider.dart';
import 'package:expense_tracker/features/categories/screens/category_create_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Kategorien')),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Fehler: $e')),
        data: (categories) => _CategoriesList(categories: categories),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const CategoryCreateScreen(),
          ),
        ),
        tooltip: 'Neue Kategorie',
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
    if (categories.isEmpty) {
      return const _EmptyState();
    }

    final defaults = categories.where((c) => c.isDefault).toList();
    final customs = categories.where((c) => c.isCustom).toList();

    return ListView(
      padding: const EdgeInsets.only(bottom: 80), // Platz für FAB
      children: [
        if (defaults.isNotEmpty) ...[
          const _SectionHeader(text: 'Standardkategorien'),
          ...defaults.map((c) => _CategoryTile(category: c)),
        ],
        if (customs.isNotEmpty) ...[
          const _SectionHeader(text: 'Eigene Kategorien'),
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kategorie löschen?'),
        content: Text(
          '"${category.name}" wird unwiderruflich gelöscht. '
          'Bestehende Ausgaben in dieser Kategorie bleiben erhalten, '
          'zeigen aber keinen Kategorie-Namen mehr an.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Löschen'),
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
    return ListTile(
      leading: CategoryAvatar(iconName: category.icon),
      title: Text(category.name),
      // Standardkategorien zeigen keinen Lösch-Button —
      // sie sind Teil des Schemas und werden zentral verwaltet.
      trailing: category.isCustom
          ? IconButton(
              icon: const Icon(Icons.delete_outline),
              color: Colors.red,
              tooltip: 'Löschen',
              onPressed: () => _confirmDelete(context, ref),
            )
          : null,
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.category_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Keine Kategorien vorhanden',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(
            'Tippe auf + um eine zu erstellen',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
