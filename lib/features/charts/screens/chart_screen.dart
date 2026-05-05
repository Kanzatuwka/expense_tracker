import 'package:flutter/material.dart';

class ChartScreen extends StatelessWidget {
  const ChartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pie_chart_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Diagramme', style: TextStyle(color: Colors.grey)),
            Text(
              'Demnächst verfügbar',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
