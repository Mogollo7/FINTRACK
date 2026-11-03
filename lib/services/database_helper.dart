import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/models.dart';

/// SQLite local (fintrack.db): movimientos, activos/pasivos y límites.
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._();
  DatabaseHelper._();
  Database? _db;

  Future<Database> get db async => _db ??= await openDatabase(
        join(await getDatabasesPath(), 'fintrack.db'),
        version: 2,
        onCreate: (d, _) => _create(d),
        onUpgrade: (d, old, _) async {
          if (old < 2) await _create(d);
        },
      );

  Future<void> _create(Database d) async {
    await d.execute('''CREATE TABLE IF NOT EXISTS movements (
      id INTEGER PRIMARY KEY AUTOINCREMENT, amount REAL NOT NULL, isIncome INTEGER NOT NULL,
      category TEXT NOT NULL, kind TEXT NOT NULL, note TEXT, date TEXT NOT NULL, photoPath TEXT)''');
    await d.execute('''CREATE TABLE IF NOT EXISTS assets (
      id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, amount REAL NOT NULL, isLiability INTEGER NOT NULL)''');
    await d.execute('''CREATE TABLE IF NOT EXISTS limits (
      id INTEGER PRIMARY KEY AUTOINCREMENT, category TEXT, period TEXT NOT NULL, amount REAL NOT NULL)''');
    await d.insert('limits', {'category': null, 'period': 'week', 'amount': 50000});
    await d.insert('limits', {'category': null, 'period': 'month', 'amount': 150000});
  }

  Future<List<Movement>> movements() async =>
      (await (await db).query('movements', orderBy: 'date DESC')).map(Movement.fromMap).toList();
  Future<int> addMovement(Movement m) async => (await db).insert('movements', m.toMap()..remove('id'));
  Future<void> updateMovement(Movement m) async => (await db).update('movements', m.toMap(), where: 'id=?', whereArgs: [m.id]);
  Future<void> deleteMovement(int id) async => (await db).delete('movements', where: 'id=?', whereArgs: [id]);

  Future<List<AssetItem>> assets() async => (await (await db).query('assets')).map(AssetItem.fromMap).toList();
  Future<void> addAsset(AssetItem a) async => (await db).insert('assets', a.toMap()..remove('id'));
  Future<void> deleteAsset(int id) async => (await db).delete('assets', where: 'id=?', whereArgs: [id]);

  Future<List<LimitItem>> limits() async => (await (await db).query('limits')).map(LimitItem.fromMap).toList();
  Future<void> addLimit(LimitItem l) async => (await db).insert('limits', l.toMap()..remove('id'));
  Future<void> updateLimit(LimitItem l) async => (await db).update('limits', l.toMap(), where: 'id=?', whereArgs: [l.id]);
  Future<void> deleteLimit(int id) async => (await db).delete('limits', where: 'id=?', whereArgs: [id]);

  /// Borra todos los datos (eliminar cuenta / importar).
  Future<void> wipe() async {
    final d = await db;
    for (final t in ['movements', 'assets', 'limits']) {
      await d.delete(t);
    }
    await d.insert('limits', {'category': null, 'period': 'week', 'amount': 50000});
    await d.insert('limits', {'category': null, 'period': 'month', 'amount': 150000});
  }
}
