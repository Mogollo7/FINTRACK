import 'package:flutter/material.dart';

/// Categorías del mockup (pantalla «Agregar»).
const expenseCats = <String, IconData>{
  'Compras': Icons.shopping_cart,
  'Alimentos': Icons.restaurant,
  'Teléfono': Icons.phone_iphone,
  'Educación': Icons.school,
  'Deporte': Icons.sports_soccer,
  'Transporte': Icons.directions_bus,
  'Salud': Icons.medical_services,
  'Hogar': Icons.home,
  'Regalos': Icons.card_giftcard,
  'Mascota': Icons.pets,
  'Otra': Icons.add,
};
const incomeCats = <String, IconData>{
  'Mesada': Icons.savings,
  'Trabajo': Icons.work,
  'Beca': Icons.school,
  'Regalo': Icons.card_giftcard,
  'Otra': Icons.add,
};
IconData catIcon(String c) => expenseCats[c] ?? incomeCats[c] ?? Icons.circle;

const kFijo = 'fijo', kNecesario = 'necesario', kHormiga = 'hormiga';
const antLimit = 20000.0; // un gasto de hasta $20.000 se cuenta como hormiga

/// Clasifica el gasto: pequeño = hormiga; vivienda/estudio/salud/teléfono = fijo; el resto = necesario.
String classify(String cat, double amount) {
  if (amount <= antLimit) return kHormiga;
  return const {'Hogar', 'Educación', 'Salud', 'Teléfono'}.contains(cat) ? kFijo : kNecesario;
}

class Movement {
  final int? id;
  final double amount;
  final bool isIncome;
  final String category, kind, note;
  final DateTime date;
  final String? photoPath;

  Movement({this.id, required this.amount, required this.isIncome, required this.category, required this.kind,
      required this.note, required this.date, this.photoPath});

  bool get isAnt => !isIncome && kind == kHormiga;

  Movement copyWith({double? amount, String? category, String? kind, String? note, DateTime? date, String? photoPath}) =>
      Movement(
        id: id,
        amount: amount ?? this.amount,
        isIncome: isIncome,
        category: category ?? this.category,
        kind: kind ?? this.kind,
        note: note ?? this.note,
        date: date ?? this.date,
        photoPath: photoPath ?? this.photoPath,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'amount': amount,
        'isIncome': isIncome ? 1 : 0,
        'category': category,
        'kind': kind,
        'note': note,
        'date': date.toIso8601String(),
        'photoPath': photoPath,
      };

  factory Movement.fromMap(Map<String, dynamic> m) => Movement(
        id: m['id'] as int?,
        amount: (m['amount'] as num).toDouble(),
        isIncome: (m['isIncome'] as int) == 1,
        category: m['category'] as String,
        kind: m['kind'] as String,
        note: (m['note'] as String?) ?? '',
        date: DateTime.parse(m['date'] as String),
        photoPath: m['photoPath'] as String?,
      );
}

class AssetItem {
  final int? id;
  final String name;
  final double amount;
  final bool isLiability;
  AssetItem({this.id, required this.name, required this.amount, required this.isLiability});

  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'amount': amount, 'isLiability': isLiability ? 1 : 0};
  factory AssetItem.fromMap(Map<String, dynamic> m) => AssetItem(
      id: m['id'] as int?, name: m['name'] as String, amount: (m['amount'] as num).toDouble(), isLiability: (m['isLiability'] as int) == 1);
}

/// Límite de gasto: `category == null` → gasto hormiga del periodo.
class LimitItem {
  final int? id;
  final String? category;
  final String period; // 'week' | 'month'
  final double amount;
  LimitItem({this.id, this.category, required this.period, required this.amount});

  Map<String, dynamic> toMap() => {'id': id, 'category': category, 'period': period, 'amount': amount};
  factory LimitItem.fromMap(Map<String, dynamic> m) => LimitItem(
      id: m['id'] as int?, category: m['category'] as String?, period: m['period'] as String, amount: (m['amount'] as num).toDouble());
}
