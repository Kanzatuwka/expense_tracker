import 'package:expense_tracker/core/l10n/locale_provider.dart';
import 'package:expense_tracker/core/theme/theme_provider.dart';
import 'package:expense_tracker/features/auth/models/auth_user.dart';
import 'package:expense_tracker/features/auth/providers/auth_provider.dart';
import 'package:expense_tracker/features/categories/screens/categories_screen.dart';
import 'package:expense_tracker/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final authAsync = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileTitle)),
      body: authAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.errorPrefix(e))),
        data: (user) {
          if (user == null) {
            return Center(child: Text(l10n.notSignedIn));
          }
          return _ProfileBody(user: user);
        },
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  final AuthUser user;

  const _ProfileBody({required this.user});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        _ProfileHeader(user: user),
        const Divider(height: 32),
        _SettingsTile(
          icon: Icons.category_outlined,
          label: l10n.manageCategories,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CategoriesScreen()),
          ),
        ),
        const _ThemeSettingsTile(),
        const _LanguageSettingsTile(),
        _SettingsTile(
          icon: Icons.info_outline,
          label: l10n.aboutApp,
          trailing: l10n.appVersion,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.comingSoon),
                duration: const Duration(seconds: 2),
              ),
            );
          },
        ),
        const SizedBox(height: 32),
        const _SignOutButton(),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final AuthUser user;

  const _ProfileHeader({required this.user});

  String _initial(String fallback) {
    final source = user.displayName ?? user.email ?? fallback;
    if (source.isEmpty) return '?';
    return source.characters.first.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: scheme.primaryContainer,
            backgroundImage: user.photoUrl != null
                ? NetworkImage(user.photoUrl!)
                : null,
            child: user.photoUrl == null
                ? Text(
                    _initial('?'),
                    style: textTheme.headlineMedium?.copyWith(
                      color: scheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            user.displayName ?? l10n.anonymous,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          if (user.email != null) ...[
            const SizedBox(height: 4),
            Text(
              user.email!,
              style: textTheme.bodyMedium?.copyWith(color: scheme.secondary),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class _ThemeSettingsTile extends ConsumerWidget {
  const _ThemeSettingsTile();

  static String _label(BuildContext context, ThemeMode mode) {
    final l10n = AppLocalizations.of(context)!;
    switch (mode) {
      case ThemeMode.light:
        return l10n.themeLight;
      case ThemeMode.dark:
        return l10n.themeDark;
      case ThemeMode.system:
        return l10n.themeSystem;
    }
  }

  Future<void> _openSelector(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final current = ref.read(themeModeProvider);
    final selected = await showDialog<ThemeMode>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l10n.themeChoose),
        children: [
          RadioGroup<ThemeMode>(
            groupValue: current,
            onChanged: (value) => Navigator.of(context).pop(value),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final mode in ThemeMode.values)
                  RadioListTile<ThemeMode>(
                    title: Text(_label(context, mode)),
                    value: mode,
                  ),
              ],
            ),
          ),
        ],
      ),
    );

    if (selected != null && selected != current) {
      await ref
          .read(themeModeNotifierProvider.notifier)
          .setThemeMode(selected);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final current = ref.watch(themeModeProvider);
    return _SettingsTile(
      icon: Icons.palette_outlined,
      label: l10n.themeLabel,
      trailing: _label(context, current),
      onTap: () => _openSelector(context, ref),
    );
  }
}

class _LanguageSettingsTile extends ConsumerWidget {
  const _LanguageSettingsTile();

  static String _label(BuildContext context, String code) {
    final l10n = AppLocalizations.of(context)!;
    switch (code) {
      case 'de':
        return l10n.languageGerman;
      case 'en':
        return l10n.languageEnglish;
      case 'uk':
        return l10n.languageUkrainian;
      default:
        return code;
    }
  }

  Future<void> _openSelector(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = ref.read(localeProvider);
    final current = currentLocale?.languageCode ?? 'de';

    final selected = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l10n.languageChoose),
        children: [
          RadioGroup<String>(
            groupValue: current,
            onChanged: (value) => Navigator.of(context).pop(value),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final code in supportedLanguageCodes)
                  RadioListTile<String>(
                    title: Text(_label(context, code)),
                    value: code,
                  ),
              ],
            ),
          ),
        ],
      ),
    );

    if (selected != null && selected != current) {
      await ref
          .read(localeNotifierProvider.notifier)
          .setLanguage(selected);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final current = ref.watch(localeProvider);
    final code = current?.languageCode ?? 'de';
    return _SettingsTile(
      icon: Icons.language,
      label: l10n.languageLabel,
      trailing: _label(context, code),
      onTap: () => _openSelector(context, ref),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailing;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, color: scheme.primary),
      title: Text(label),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null) ...[
            Text(trailing!, style: TextStyle(color: scheme.secondary)),
            const SizedBox(width: 8),
          ],
          Icon(Icons.chevron_right, color: scheme.secondary),
        ],
      ),
      onTap: onTap,
    );
  }
}

class _SignOutButton extends ConsumerWidget {
  const _SignOutButton();

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.signOutQuestion),
        content: Text(l10n.signOutDescription),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.signOut),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authProvider.notifier).signOut();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: OutlinedButton.icon(
        onPressed: () => _confirmSignOut(context, ref),
        icon: const Icon(Icons.logout),
        label: Text(l10n.signOut),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          foregroundColor: Colors.red,
          side: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }
}
