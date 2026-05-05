/// Domain-Entität: Ausgabe.
///
/// Pure Dart — keine Abhängigkeit von Firestore oder Flutter.
/// Konvertierung von Firestore-spezifischen Typen (z.B. `Timestamp`) erfolgt
/// in [FirestoreExpenseRepository] an der Datenschicht-Grenze.
class Expense {
  final String id;
  final double amount;
  final String categoryId; // Referenz auf categories/{categoryId}
  final DateTime date;
  final String note;
  final String userId;
  final DateTime createdAt;

  const Expense({
    required this.id,
    required this.amount,
    required this.categoryId,
    required this.date,
    required this.note,
    required this.userId,
    required this.createdAt,
  });

  /// Konvertiert eine Map mit primitiven Dart-Typen in eine [Expense].
  /// Daten müssen bereits zu Dart-Typen normalisiert sein (DateTime statt
  /// Timestamp). Die Repository-Schicht ist für diese Normalisierung zuständig.
  factory Expense.fromMap(Map<String, dynamic> data, String id) {
    return Expense(
      id: id,
      amount: (data['amount'] as num).toDouble(),
      // Backward Compatibility: ältere Dokumente nutzen 'category' (string)
      categoryId:
          data['categoryId'] as String? ?? data['category'] as String? ?? '',
      date: data['date'] as DateTime,
      note: data['note'] as String? ?? '',
      userId: data['userId'] as String,
      createdAt: data['createdAt'] as DateTime,
    );
  }

  /// Serialisiert die Entität in eine Map mit primitiven Dart-Typen.
  /// Die Repository-Schicht wandelt DateTime ggf. in Firestore-Timestamps um.
  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'categoryId': categoryId,
      'date': date,
      'note': note,
      'userId': userId,
      'createdAt': createdAt,
    };
  }
}
