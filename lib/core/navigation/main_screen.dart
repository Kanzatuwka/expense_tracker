import 'package:expense_tracker/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:expense_tracker/features/charts/screens/chart_screen.dart';
import 'package:expense_tracker/features/expenses/screens/expense_form_screen.dart';
import 'package:expense_tracker/features/expenses/screens/expenses_list_screen.dart';
import 'package:expense_tracker/features/profile/screens/profile_screen.dart';
import 'package:expense_tracker/features/reports/screens/report_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const ExpensesListScreen(),
    const ChartScreen(),
    const SizedBox(),
    const ReportScreen(),
    const ProfileScreen(),
  ];

  Future<void> _openCreateScreen() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ExpenseFormScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex == 2 ? 0 : _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              icon: Icons.receipt_long_outlined,
              label: l10n.navRecords,
              index: 0,
              currentIndex: _currentIndex,
              onTap: () => setState(() => _currentIndex = 0),
            ),
            _NavItem(
              icon: Icons.pie_chart_outline,
              label: l10n.navChart,
              index: 1,
              currentIndex: _currentIndex,
              onTap: () => setState(() => _currentIndex = 1),
            ),
            const SizedBox(width: 48),
            _NavItem(
              icon: Icons.bar_chart_outlined,
              label: l10n.navReports,
              index: 3,
              currentIndex: _currentIndex,
              onTap: () => setState(() => _currentIndex = 3),
            ),
            _NavItem(
              icon: Icons.person_outline,
              label: l10n.navMe,
              index: 4,
              currentIndex: _currentIndex,
              onTap: () => setState(() => _currentIndex = 4),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateScreen,
        shape: const CircleBorder(),
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int currentIndex;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = currentIndex == index;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey,
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
