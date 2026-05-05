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
  // Aktuell ausgewählter Tab-Index
  // 0=Records, 1=Chart, 2=+(Aktion), 3=Reports, 4=Me
  int _currentIndex = 0;

  // Screens für jeden Tab — Index 2 ist ein Platzhalter
  final List<Widget> _screens = [
    const ExpensesListScreen(),
    const ChartScreen(),
    const SizedBox(), // Platzhalter für "+" Button
    const ReportScreen(),
    const ProfileScreen(),
  ];

  // "+" Button öffnet das Formular im Create-Modus
  Future<void> _openCreateScreen() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ExpenseFormScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Aktuellen Screen anzeigen — Index 2 wird nie direkt angezeigt
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
            // Records
            _NavItem(
              icon: Icons.receipt_long_outlined,
              label: 'Records',
              index: 0,
              currentIndex: _currentIndex,
              onTap: () => setState(() => _currentIndex = 0),
            ),
            // Chart
            _NavItem(
              icon: Icons.pie_chart_outline,
              label: 'Chart',
              index: 1,
              currentIndex: _currentIndex,
              onTap: () => setState(() => _currentIndex = 1),
            ),
            // Platz für FAB
            const SizedBox(width: 48),
            // Reports
            _NavItem(
              icon: Icons.bar_chart_outlined,
              label: 'Reports',
              index: 3,
              currentIndex: _currentIndex,
              onTap: () => setState(() => _currentIndex = 3),
            ),
            // Me
            _NavItem(
              icon: Icons.person_outline,
              label: 'Me',
              index: 4,
              currentIndex: _currentIndex,
              onTap: () => setState(() => _currentIndex = 4),
            ),
          ],
        ),
      ),
      // Zentraler "+" Button
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateScreen,
        shape: const CircleBorder(),
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

// Einzelnes Nav-Item
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
