import 'package:expense_tracker/features/auth/models/auth_user.dart';
import 'package:expense_tracker/features/auth/providers/auth_provider.dart';
import 'package:expense_tracker/features/categories/screens/categories_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: authAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Fehler: $e')),
        data: (user) {
          // Sollte in der Praxis nicht eintreten — der ProfileScreen ist nur
          // sichtbar, wenn der Benutzer angemeldet ist (siehe main.dart).
          if (user == null) {
            return const Center(child: Text('Nicht angemeldet'));
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

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bald verfügbar'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        _ProfileHeader(user: user),
        const Divider(height: 32),
        _SettingsTile(
          icon: Icons.category_outlined,
          label: 'Kategorien verwalten',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const CategoriesScreen(),
            ),
          ),
        ),
        _SettingsTile(
          icon: Icons.palette_outlined,
          label: 'Theme',
          trailing: 'System',
          onTap: () => _showComingSoon(context),
        ),
        _SettingsTile(
          icon: Icons.language,
          label: 'Sprache',
          trailing: 'Deutsch',
          onTap: () => _showComingSoon(context),
        ),
        _SettingsTile(
          icon: Icons.info_outline,
          label: 'Über die App',
          trailing: 'v0.1.0',
          onTap: () => _showComingSoon(context),
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

  // Erstes Zeichen aus displayName oder Email — als Fallback wenn kein Foto da ist.
  String get _initial {
    final source = user.displayName ?? user.email ?? '?';
    if (source.isEmpty) return '?';
    return source.characters.first.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
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
                    _initial,
                    style: textTheme.headlineMedium?.copyWith(
                      color: scheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            user.displayName ?? 'Anonym',
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Abmelden?'),
        content: const Text('Du wirst von der App abgemeldet.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Abmelden'),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: OutlinedButton.icon(
        onPressed: () => _confirmSignOut(context, ref),
        icon: const Icon(Icons.logout),
        label: const Text('Abmelden'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          foregroundColor: Colors.red,
          side: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }
}
