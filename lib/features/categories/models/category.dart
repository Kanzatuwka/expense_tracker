/// Domain-Entität: Kategorie.
///
/// Pure Dart — keine Abhängigkeit von Firestore oder Flutter.
class Category {
  final String id;
  final String name;
  final String icon;
  final bool isCustom;
  final bool isDefault;
  final DateTime createdAt;

  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.isCustom,
    required this.isDefault,
    required this.createdAt,
  });

  factory Category.fromMap(Map<String, dynamic> data, String id) {
    return Category(
      id: id,
      name: data['name'] as String,
      icon: data['icon'] as String,
      isCustom: data['isCustom'] as bool,
      isDefault: data['isDefault'] as bool,
      createdAt: data['createdAt'] as DateTime,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'icon': icon,
      'isCustom': isCustom,
      'isDefault': isDefault,
      'createdAt': createdAt,
    };
  }
}
