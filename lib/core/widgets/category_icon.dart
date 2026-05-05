import 'package:flutter/material.dart';

/// Zentrale Mapping-Tabelle: Icon-Name (string in Firestore) → [IconData].
///
/// Single Source of Truth — wird von [iconDataForCategory] und allen UI-Komponenten
/// gemeinsam genutzt. Neue Standardkategorien werden hier ergänzt.
const Map<String, IconData> kCategoryIcons = <String, IconData>{
  'restaurant': Icons.restaurant_outlined,
  'directions_car': Icons.directions_car_outlined,
  'favorite': Icons.favorite_outline,
  'movie': Icons.movie_outlined,
  'receipt': Icons.receipt_outlined,
};

/// Fallback-Icon für unbekannte oder fehlende Icon-Namen.
const IconData kFallbackCategoryIcon = Icons.receipt_outlined;

/// Reine Lookup-Funktion ohne Widget-Kontext — testbar.
///
/// Liefert [kFallbackCategoryIcon] für `null` oder unbekannte Namen.
IconData iconDataForCategory(String? iconName) {
  if (iconName == null) return kFallbackCategoryIcon;
  return kCategoryIcons[iconName] ?? kFallbackCategoryIcon;
}

/// Avatar-Darstellung einer Kategorie für ListTile-Kontexte.
///
/// Kapselt das `CircleAvatar`-Styling, das sonst an mehreren Stellen
/// dupliziert würde. Farben kommen aus dem aktuellen [ColorScheme].
class CategoryAvatar extends StatelessWidget {
  const CategoryAvatar({super.key, required this.iconName, this.size = 20});

  final String? iconName;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CircleAvatar(
      backgroundColor: scheme.secondaryContainer,
      child: Icon(
        iconDataForCategory(iconName),
        color: scheme.onSecondaryContainer,
        size: size,
      ),
    );
  }
}
