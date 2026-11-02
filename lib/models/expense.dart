class Expense {
  final int? id;
  final double amount;
  final String category;
  final String note;
  final DateTime date;
  final String? photoPath;
  final bool isAnt; // true si es clasificado como gasto hormiga

  Expense({
    this.id,
    required this.amount,
    required this.category,
    required this.note,
    required this.date,
    this.photoPath,
    this.isAnt = true,
  });

  Expense copyWith({
    int? id,
    double? amount,
    String? category,
    String? note,
    DateTime? date,
    String? photoPath,
    bool? isAnt,
  }) {
    return Expense(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      note: note ?? this.note,
      date: date ?? this.date,
      photoPath: photoPath ?? this.photoPath,
      isAnt: isAnt ?? this.isAnt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'category': category,
      'note': note,
      'date': date.toIso8601String(),
      'photoPath': photoPath,
      'isAnt': isAnt ? 1 : 0,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int?,
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] as String,
      note: map['note'] as String? ?? '',
      date: DateTime.parse(map['date'] as String),
      photoPath: map['photoPath'] as String?,
      isAnt: (map['isAnt'] as int? ?? 1) == 1,
    );
  }
}

